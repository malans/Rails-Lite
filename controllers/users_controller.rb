require_relative './../models/user.rb'
require 'byebug'

class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def new

  end

  def create
    debugger;
    @user = User.new(params["user"])  # implement require and permit
    if @user.save
      sign_in(@user)
      render :show
    else
      flash["Error"] = "Username or password invalid"
      render :new
    end
  end

  # def create
  #   @user = User.new(user_params)
  #   if @user.save
  #     sign_in!(@user)
  #     redirect_to user_url(@user)
  #   else
  #     flash.now[:errors] = @user.errors.full_messages
  #     render :new
  #   end
  # end

  def show
    @user = User.find(Integer(params["id"]))
    render :show
  end

end
