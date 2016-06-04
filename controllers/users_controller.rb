class UsersController < ApplicationController
  before_action :require_login, only: [:show, :index]
  before_action :require_not_logged_in, only: [:new]

  def index
    @users = User.all
  end

  def new

  end

  def create
    @user = User.new(params["user"])  # implement require and permit
    if @user.save
      sign_in(@user)
      render :show
    else
      flash.now["Error"] = @user.errors
      render :new
    end
  end

  def show
    @user = User.find(Integer(params["id"]))
    render :show
  end

end
