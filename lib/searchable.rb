require_relative 'db_connection'
require_relative 'sql_object'

class Relation
  include Enumerable

  attr_accessor :where_params, :query_result, :loaded

  def initialize(model_class)
    @loaded = false
    @model_class = model_class

    #query defaults
    @select = "*"
    @from = table_name
    @join = []
    @where_params = {}
  end

  def each(&block)
    run_query unless @loaded
    @query_result.each do |object|
      block.call(object)
    end
  end

  def model_class
    @model_class
  end

  def table_name
    @model_class.table_name
  end

  def select(select_str)
    @select = select_str
    self
  end

  def from(from_str)
    @from = from_str
    self
  end

  def join(join_str)
    @join << join_str
    self
  end

  def where(params)
    @loaded = false
    where_params.merge!(params)
    self
  end

  def select_line
    "SELECT " + @select
  end

  def from_line
    "FROM " + @from
  end

  def join_line
    @join.empty? ?
    "" :
    "JOIN " + @join.join(" ")
  end

  def where_line
    where_params.keys.empty? ?
      "" :
      "WHERE " + where_params.keys.map { |key| "#{key} = ?" }.join(" AND ")
  end

  def merge(relation)
    @loaded = false
    where_params.merge!(relation.where_params)
    self
  end

  def current_query
    puts <<-SQL_QUERY
    #{select_line}
    #{from_line}
    #{join_line}
    #{where_line}
    SQL_QUERY
  end

  def run_query
    unless @loaded
      results = DBConnection.execute(<<-SQL, where_params.values)
        #{select_line}
        #{from_line}
        #{join_line}
        #{where_line}
      SQL
      @loaded = true
      @query_result = model_class.parse_all(results)
    end

    self  # return a Relation object
  end

  def inspect
    run_query
    p @query_result  # return an Array
  end

end
