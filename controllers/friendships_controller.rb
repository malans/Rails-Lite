require 'byebug'

class FriendshipsController < ApplicationController
  def create
    requesting_id = Integer(params["friendship"]["requesting_id"])
    requested_id = Integer(params["friendship"]["requested_id"])

    Friendship.create({user_id: requesting_id, friend_id: requested_id, status: "REQUESTED"})
    Friendship.create({user_id: requesting_id, friend_id: requested_id, status: "PENDING"})

    # # This should be a method in SQLObject called transaction,
    # # like ActiveRecord::Base.transaction
    # results = DBConnection.execute(<<-SQL, requesting_id, requested_id, requested_id, requesting_id)
    #   BEGIN TRANSACTION;
    #     INSERT INTO
    #       friendships (USER_ID, FRIEND_ID, STATUS)
    #     VALUES
    #       (?, ?, "REQUESTED")
    #     INSERT INTO
    #       friendships (USER_ID, FRIEND_ID, STATUS)
    #     VALUES
    #       (?, ?, "PENDING")
    #   END TRANSACTION;
    # SQL
    # debugger;
  end

end
