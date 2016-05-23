require_relative '../lib/router'
Dir['./controllers/*.rb'].each {|file| require file }

$router.draw do
  # add routes below
  get Regexp.new(/\A\/\z/), StaticPagesController, :root
  get Regexp.new(/^\/users\/(?<id>\d+)$/), UsersController, :show
  get Regexp.new(/^\/users$/), UsersController, :index
  get Regexp.new(/^\/users\/new$/), UsersController, :new
  post Regexp.new(/^\/users$/), UsersController, :create
  get Regexp.new(/^\/session\/new$/), SessionsController, :new
  post Regexp.new(/^\/session$/), SessionsController, :create
end
