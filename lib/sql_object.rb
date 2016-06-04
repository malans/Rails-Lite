require_relative 'db_connection'
require 'active_support/inflector'
require 'bcrypt'
require 'byebug'
require_relative './searchable'
require_relative './associatable'
require_relative './validatable'
require_relative './delegate'

class SQLObject
  extend Delegate
  # delegate method called in class scope delegates instance method call to instance method

  class << self
    extend Delegate
    # delegate method call in singleton class scope delegates class method call to class method

    attr_accessor :after_initialize_methods

    delegate :select, :from, :join, :where, to: :newRelation
  end

  def self.newRelation
    Relation.new(self)
  end

  def self.columns
    # queries the database for columns if @columns has not been set yet
    # returns array of columns as symbols
    # only queries the DB once
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL
    cols.map!(&:to_sym)
    @columns = cols
  end

  def self.finalize!
    # defines getter and setter methods for the attributes of this object (a model object)
    # defines convenience methods to query the database by specific column (ex: find_by_username)
    self.columns.each do |column_name|
      define_method(column_name) { self.attributes[column_name] }
      define_method("#{column_name}=") { |value| self.attributes[column_name] = value }
      define_singleton_method("find_by_#{column_name}") do |column_value|
        results = DBConnection.execute(<<-SQL, column_value)
          SELECT
            #{self.table_name}.*
          FROM
            #{self.table_name}
          WHERE
            #{table_name}.#{column_name} = ?
        SQL

        parse_all(results).first
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{table_name}.id = ?
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    # sets attributes on model object for each attribute passed in params
    # raises error if the attribute doesn't exist for this model
    # calls after_initialize_methods if there are any

    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      #raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      begin
        self.send("#{attr_name}=", value)
      rescue NoMethodError
        raise UnknownAttributeError, "Unknown attribute '#{attr_name}'"
      end
    end

    unless self.class.after_initialize_methods.nil?
      self.class.after_initialize_methods.each { |method| self.send(method) }
    end
  end

  def ==(otherObject)
    self.class.table_name == otherObject.class.table_name &&
    self.attributes.keys.all? { |attr| send(attr) == otherObject.send(attr)}
  end

  def equal_column_values?(*columns, otherObject)
    begin
      columns.each do |column|
        return false if self.send(column.to_sym) != otherObject.send(column.to_sym)
      end
    rescue NoMethodError
      raise UnknownAttributeError, "Unknown attribute"
    end
    true
  end

  def self.create(params = {})
    newSQLObject = self.new(params)
    newSQLObject.save
  end

  def self.after_initialize(*methods)
    # sets class instance variable @after_initialize_methods
    # this variable is unique for each subclass of SQLObject
    @after_initialize_methods = methods
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |column| self.send(column) }
  end

  def insert
    if valid?
      # drop 1 to avoid inserting id (the first column)
      columns = self.class.columns.drop(1)
      col_names = columns.map(&:to_s).join(", ")
      question_marks = (["?"] * columns.count).join(", ")
      results = DBConnection.execute(<<-SQL, *attribute_values.drop(1))
        INSERT INTO
          #{self.class.table_name} (#{col_names})
        VALUES
          (#{question_marks})
      SQL
      self.id = DBConnection.last_insert_row_id
      return true
    end
    false
  rescue
    false
  end

  def update
    if valid?
      set_line = self.class.columns.map { |column| "#{column} = ?"}.join(", ")
      results = DBConnection.execute(<<-SQL, *attribute_values, id)
        UPDATE
          #{self.class.table_name}
        SET
          #{set_line}
        WHERE
          #{self.class.table_name}.id = ?
      SQL
      return true
    end
    false
  rescue
    false
  end

  def errors
    @errors ||= reset_errors
  end

  def reset_errors
    @errors = Hash.new { |h,k| h[k] = [] }
  end

  def errors=(column, message)
    errors[column] = message
  end


  def valid?
    reset_errors
    self.class.validation_options.each do |type, validation_options|
      validation_options.each { |validation_option| validation_option.validate(self) }
    end

    return true if errors.empty?
    false
  end

  def save
    id.nil? ? insert : update
  end
end

class UnknownAttributeError < StandardError

end
