require 'byebug'

class FriendshipsController < ApplicationController
  # Create two entries for each friendship request
  # Should create a method "transaction" in SQLObject to perform operations on
  # friendships table, which occur always in pairs.
  def create
    requesting_id = Integer(params["friendship"]["requesting_id"])
    requested_id = Integer(params["friendship"]["requested_id"])

    Friendship.create({user_id: requesting_id, friend_id: requested_id, status: "REQUESTED"})
    Friendship.create({user_id: requesting_id, friend_id: requested_id, status: "PENDING"})
  end

  def update
    first_entry = Friendship.find(params[:id])
    second_entry = Friendship.where({user_id: first_entry.friend_id, friend_id: first_entry.user_id})

    first_entry.status = "ACCEPTED"
    second_entry.status = "ACCEPTED"

    first_entry.update
    second_entry.update
  end

end
