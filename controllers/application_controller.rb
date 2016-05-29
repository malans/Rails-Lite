class ApplicationController < ControllerBase

  protect_from_forgery with: :exception

  def sign_in(user)
    @current_user = user
    session["session_token"] = user.session_token
  end

  def current_user
    return nil if session["session_token"].nil?
    @current_user = User.find_by_session_token(session["session_token"])
  end

  def require_login
    unless signed_in?
      flash[:Errors] = ["Need to be signed in."]
      redirect_to "http://localhost:3000/session/new"
    end
  end

  def require_not_logged_in
    redirect_to "http://localhost:3000/users/#{current_user.id}" if signed_in?
  end

  def signed_in?
    !!current_user
  end

  def logout!
    current_user.try(:reset_session_token)
    session["session_token"] = nil
  end

end
