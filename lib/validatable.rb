require_relative './util.rb'

class Validator
  include Util
  attr_accessor :columns, :options
end

class PresenceValidator < Validator
  def initialize(columns, options)
    @columns = columns
    @options = options
  end

  def validate(record)
    @columns.each do |column|
      column_value = record.send(column)
      if @options
        record.errors[column] << "can't be blank" if blank?(column_value)
      else
        record.errors[column] << "must be blank" unless blank?(column_value)
      end
    end
  end
end

class LengthValidator < Validator
  def initialize(columns, options)
    @columns = columns
    defaults = {
      minimum: nil,
      maximum: nil,
      in: nil,
      is: nil,
      allow_nil: false
    }
    @options = defaults.merge(options)
  end

  def validate(record)
    @columns.each do |column|
      column_value = record.send(column)
      next if @options[:allow_nil] && column_value.nil?
      @options.each do |option, option_value|
        next if option_value.nil?
        case option
        when :minimum
          record.errors[column] << "Must have length > #{option_value}" if column_value.length < option_value
        when :maximum
          record.errors[column] << "Must have length < #{option_value}" if column_value.length > option_value
        when :in
          record.errors[column] << "Must have length in interval #{option_value}" unless option_value === column_value.length
        when :is
          record.errors[column] << "Must have length #{option_value}" unless column_value.length == option_value
        end
      end
    end
  end
end

class UniquenessValidator < Validator
  def initialize(columns, options)
    @columns = columns
    @options = options
  end

  def validate(record)
    where_scope_hash = {}
    if options.is_a?(Hash)
      scope_fields = [].concat(options[:scope])
      scope_fields.each do |field|
        where_scope_hash[field] = record.send(field)
      end
    end
    @columns.each do |column|
      column_value = record.send(column)
      where_hash = {column => record.send(column)}.merge(where_scope_hash)
      otherRecords = record.class.where(where_hash).inspect
      record.errors[column] << "Must have unique #{where_hash.keys.length == 1 ?
        "" : "combination of"} #{where_hash.keys.join(', ')}." unless otherRecords.empty?
    end
  end
end

module Validatable
  def validates(*columns, validations)
    validations.each do |validation, options|
      case validation
      when :presence
        validation_options[validation] << PresenceValidator.new(columns, options)
      when :length
        validation_options[validation] << LengthValidator.new(columns, options)
      when :uniqueness
        validation_options[validation] << UniquenessValidator.new(columns, options)
      end
    end
  end

  def validation_options
    @validation_options ||= Hash.new {|h,k| h[k] = []}
  end
end

class SQLObject
  extend Validatable
end
