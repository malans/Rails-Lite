class FriendshipsController < ApplicationController
  # Create two entries for each friendship request
  # Should create a method "transaction" in SQLObject to perform operations on
  # friendships table, which occur always in pairs.
  def create
    requesting_id = Integer(params["friendship"]["requesting_id"])
    requested_id = Integer(params["friendship"]["requested_id"])
    requesting_user = User.find(requesting_id)
    requested_user = User.find(requested_id)

    unless requesting_user.friends.include?(requested_user)
      Friendship.create({user_id: requesting_id, friend_id: requested_id, status: "REQUESTED"})
      Friendship.create({user_id: requested_id, friend_id: requesting_id, status: "PENDING"})
    end

    redirect_to req.referer

  end

  def update
    first_entry = Friendship.find(Integer(params["id"]))  #find needs to be updated to use Relation object
    second_entry = Friendship.where({user_id: first_entry.friend_id, friend_id: first_entry.user_id}).first

    first_entry.status = "ACCEPTED"
    second_entry.status = "ACCEPTED"

    first_entry.update
    second_entry.update

    redirect_to req.referer
  end

  def destroy

  end

end
