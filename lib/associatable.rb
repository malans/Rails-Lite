require_relative 'searchable'
require_relative './util.rb'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
    :query_options
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.camelcase,
      query_options: {}
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {}, query_options)
    defaults = {
      foreign_key: "#{self_class_name.underscore}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase,
      query_options: query_options
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  include Util
  # defines a method to access the association
  # ex: cat.belongs_to(owner) defines method cat.owner
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    # gets the BelongsToOptions object that contains information about the association
    # performs a database query on the table represented by model Owner, where
    # the primary_key in the owners table matches the foreign_key owner_id
    define_method(name) do
      options = self.class.assoc_options[name]

      foreign_key_value = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => foreign_key_value)
        .run_query
        .query_result
        .first
    end
  end

  def has_many(name, options = {}, &query_options)
    if options.has_key?(:through) && options.has_key?(:source)
      has_many_through(name, options[:through], options[:source])
    else
      self.assoc_options[name] = HasManyOptions.new(name,
                                    self.name,
                                    options,
                                    block_given? ? query_options.call.where_params : {})
      define_method(name) do
        options = self.class.assoc_options[name]

        primary_key_value = self.send(options.primary_key)
        # return value is a Relation object
        options
          .model_class
          .where({options.foreign_key => primary_key_value}).where(options.query_options).run_query
      end
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_fk = through_options.foreign_key
      through_pk = through_options.primary_key

      source_table = source_options.table_name
      source_fk = source_options.foreign_key
      source_pk = source_options.primary_key

      query_line = through_where_line.concat(source_where_line).unshift("#{through_table}.#{through_fk}".to_sym)
      relation = source_options.model_class.select("#{source_table}.*")
                                 .from(through_table)
                                 .join("#{source_table} ON #{through_table}.#{source_fk} = #{source_table}.#{source_pk}")
                                 .where("#{through_table}.#{through_pk}".to_sym => send(through_fk))

      relation.run_query.query_result.first
    end
  end

  def has_many_through(name, through_name, source_name)
    # returns a Relation object
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_fk = through_options.foreign_key
      through_pk = through_options.primary_key

      through_where_line = through_options
            .query_options
            .keys
            .map { |key| "#{through_table}.#{key}".to_sym }
      through_where_values = through_options.query_options.values

      source_table = source_options.table_name
      source_fk = source_options.foreign_key
      source_pk = source_options.primary_key

      source_where_line = source_options
            .query_options
            .keys
            .map { |key| "#{source_table}.#{key}".to_sym }
      source_where_values = source_options.query_options.values

      query_values = through_where_values.concat(source_where_values)

      if through_options.is_a?(HasManyOptions) && source_options.is_a?(BelongsToOptions)
        query_line = through_where_line.concat(source_where_line).unshift("#{through_table}.#{through_fk}".to_sym)
        relation = source_options.model_class.select("#{source_table}.*")
                                   .from(through_table)
                                   .join("#{source_table} ON #{through_table}.#{source_fk} = #{source_table}.#{source_pk}")
                                   .where(query_line.zip(query_values.unshift(send(through_pk))).to_h)  # WHERE #{through_table}.#{through_fk} = ? #{through_where_line} #{source_where_line}
      elsif through_options.is_a?(BelongsToOptions) && source_options.is_a?(HasManyOptions)
        query_line = through_where_line.concat(source_where_line).unshift("#{through_table}.#{through_pk}".to_sym)
        relation = source_options.model_class.select("#{source_table}.*")
                                   .from(through_table)
                                   .join("#{source_table} ON #{through_table}.#{source_pk} = #{source_table}.#{source_fk}")
                                   .where(query_line.zip(query_values.unshift(send(through_fk))).to_h)  # WHERE #{through_table}.#{through_pk} = ? #{through_where_line} #{source_where_line}
      elsif through_options.is_a?(HasManyOptions) && source_options.is_a?(HasManyOptions)
        query_line = through_where_line.concat(source_where_line).unshift("#{through_table}.#{through_fk}".to_sym)
        relation = source_options.model_class.select("#{source_table}.*")
                                   .from(through_table)
                                   .join("#{source_table} ON #{through_table}.#{source_pk} = #{source_table}.#{source_fk}")
                                   .where(query_line.zip(query_values.unshift(send(through_pk))).to_h)  # WHERE #{through_table}.#{through_fk} = ? #{through_where_line} #{source_where_line}
      end
      relation.run_query
    end
  end
end

class SQLObject
  extend Associatable
end
