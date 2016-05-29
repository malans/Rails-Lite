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
        record.errors[column] = "can't be blank" if column_value.blank?
      else
        record.errors[column] = "must be blank" unless column_value.blank?
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
          record.errors[column] = "Must have length > #{option_value}" if column_value.length < option_value
        when :maximum
          record.errors[column] = "Must have length < #{option_value}" if column_value.length > option_value
        when :in
          record.errors[column] = "Must have length in interval #{option_value}" unless option_value === column_value.length
        when :is
          record.errors[column] = "Must have length #{option_value}" unless column_value.length == option_value
        end
      end
    end
  end
end

class UniquenessValidator < Validator
  def initialize(columns, options)
    @columns = columns
    defaults = {
      scope: nil,
      case_sensitive: nil,
    }
    @options = defaults.merge(options)
  end

  def validate(record)
    @columns.each do |column|
      column_value = record.send(column)
      @options.each do |option, option_value|
        next if option_value.nil?
        case option
        when :scope
          scope_fields = option_value
          User.where({column => record.send(column)})
        end
      end
    end
  end
end

module Validatable
  def validates(*columns, validations)
    debugger;
    validations.each do |validation, options|
      case validation
      when :presence
        validation_options[validation] << PresenceValidator.new(columns, options)
      when :length
        validation_options[validation] << LengthValidator.new(columns, options)
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
