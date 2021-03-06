
class SessionsController < ApplicationController
  before_action :require_not_logged_in, only: [:new]

  def new

  end

  def create
    @user = User.find_by_credentials(params["user"]["username"],
                                     params["user"]["password"])
    if @user.nil?
      flash["Error"] = "Could not find user"
      render :new
    else
      sign_in(@user)
      redirect_to "http://localhost:3000/users/#{@user.id}"
    end
  end

  def destroy
    logout!
    redirect_to "http://localhost:3000/"
  end

end
