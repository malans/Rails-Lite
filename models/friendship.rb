require_relative './../lib/sql_object'

class Friendship < SQLObject
  finalize!

  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :user_id, :friend_id, :status, presence: true
  validates :user_id, uniqueness: { scope: [:friend_id, :status] }
end
