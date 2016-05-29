class StaticPagesController < ApplicationController
  before_action :require_not_logged_in, only: [:root]

  def root

  end
end
