require_relative 'db_connection'
require_relative 'sql_object'

class Relation
  attr_accessor :where_params

  def initialize(model_class, params = {})
    @where_params = params
    @model_class = model_class
  end

  def model_class
    @model_class
  end

  def table_name
    @model_class.table_name
  end

  def where(params)
    @loaded = false
    where_params.merge!(params)
    self
  end

  def merge(relation)
    @loaded = false
    where_params.merge!(relation.where_params)
    self
  end

  def run_query
    unless @loaded
      where_line = where_params.keys.map { |key| "#{key} = ?" }.join(" AND ")
        results = DBConnection.execute(<<-SQL, where_params.values)
          SELECT
            *
          FROM
            #{table_name}
          WHERE
            #{where_line}
        SQL
      @loaded = true
    end

    @query_result = model_class.parse_all(results)
  end

  def inspect
    run_query
    @query_result.inspect
  end

end

module Searchable
  def where(params)
    Relation.new(self, params)
  end
end

class SQLObject
  extend Searchable
end
