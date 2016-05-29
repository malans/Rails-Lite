require_relative './../lib/sql_object'
require 'byebug'

class Friendship < SQLObject
  finalize!

  belongs_to :user
  belongs_to :friend, class_name: "User"
end
