require 'rubygems'
require "sinatra/reloader"
require 'sinatra/flash'
require "sinatra_warden"
require "helpers/wip_helper"
require "helpers/auth_helper"
require "omniauth"

require "models/forum"
require "models/post"
require "models/message"
require "models/user/account"
require "models/mail/mail_box"
require "models/mail/letter"


require "app/core"
require "app/auth_routes"
require "app/user_routes"
require 'date'
require 'json'


module Wippr
  class Wippr::Application < Sinatra::Base
    
    $forum_mount = "/"
  
    register Sinatra::Flash
    register Sinatra::Warden
    
    helpers Wippr::AuthHelpers
    helpers Wippr::Helpers

    register Wippr::UserRoutes
    register Wippr::AuthRoutes
    register Wippr::Core

    # Omniauth overrides
    set :auth_failure_path => "/unauthenticated"



    


  end

end
