require_relative './../lib/sql_object'
require 'byebug'

class User < SQLObject
  finalize!

  attr_reader :password

  validates :username, :password_digest, :session_token, presence: true
  validates :password, length: { minimum: 6, allow_nil: true }
  validates :username, uniqueness: true

  after_initialize :ensure_session_token

  has_many(:sent_friendship_requests,
  foreign_key: :user_id,
  primary_key: :id,
  class_name: "Friendship") { where status: "REQUESTED" }

  has_many(:pending_friendship_requests,
  foreign_key: :friend_id,
  primary_key: :id,
  class_name: "Friendship") { where status: "PENDING" }

  has_many(:accepted_friendship_requests,
  foreign_key: :user_id,
  primary_key: :id,
  class_name: "Friendship") { where status: "ACCEPTED" }

  # has_many :inverse_friendships,
  #   foreign_key: :friend_id,
  #   primary_key: :id,
  #   class_name: "Friendship"

  has_many_through :friends, :accepted_friendship_requests, :friend
  has_many_through :requested_friends, :sent_friendship_requests, :friend
  has_many_through :pending_friends, :pending_friendship_requests, :user


  def self.find_by_credentials(username, password)
    user = User.find_by_username(username)
    return nil unless user && user.valid_password?(password)
    user
  end

  def valid_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def password=(password)
    @password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def self.generate_session_token
    SecureRandom.urlsafe_base64(16)
  end

  def reset_session_token!
    self.session_token = User.generate_session_token
    self.save
    self.session_token
  end
end

def ensure_session_token
  self.session_token ||= User.generate_session_token
end
