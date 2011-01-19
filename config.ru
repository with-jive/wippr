$: << File.dirname( __FILE__)
require 'rubygems'
require 'bundler'
Bundler.require



# Let's use some middleware
require 'rack/contrib'

use Rack::Session::Cookie, :secret => '_wiprntin_nagas35asdaosn'
if development?
  use Rack::Static, :urls =>
      ["/wmd", "/fonts", "/images", "/javascripts", "/stylesheets"], :root => "public"
else
  use Rack::StaticCache, :urls =>
      ["/fonts", "/images", "/javascripts", "/stylesheets"], :root => "public"
end


Warden::Manager.serialize_into_session do |user|
  {
    :handle  => user.handle,
    :email   => user.email,
    :first_name => user.first_name,
    :last_name => user.last_name,
    :admin => user.admin,
    :facebook_uid => user.facebook_uid,
    :twitter_uid => user.twitter_uid,
    :linkedin_uid => user.linkedin_uid,
    :google_uid  => user.google_uid,
    :email => user.email,
    :password => user.password,
    :avatar => user.avatar,
    :unread => user.unread_messages,
    :mailbox => user.mailbox
  }
end
Warden::Manager.serialize_from_session do |user|
  puts "\n Deserialising... \n"
  Wippr::User::Account.new(
    :handle  => user[:handle],
    :email   => user[:email],
    :first_name => user[:first_name],
    :last_name => user[:last_name],
    :admin => user[:admin],
    :facebook_uid => user[:facebook_uid],
    :twitter_uid => user[:twitter_uid],
    :linkedin_uid => user[:linkedin_uid],
    :google_uid  => user[:google_uid],
    :email => user[:email],
    :password => user[:password],
    :avatar => user[:avatar],
    :unread_messages => user[:unread],
    :mailbox=> user[:mailbox]
  )
end


# Authentication hoops
use OmniAuth::Builder do
  provider :twitter, '25q5JGIARQdmf65TnHsYg', 'PqJqgDy88Hk8V0KJ4RgKQJCfnBSj5TWTExAvu5oWk'
  provider :facebook, 'a7d37840e643bb15a17f81b73bbe02ce', '6bb9683037094784bdc3eb98d12439a5'
end

use Warden::Manager do |manager|
  manager.default_strategies :couch
  manager.failure_app = Wippr::Application
end

Warden::Strategies.add(:couch) do
  def valid?
    params["email"] || params["password"]
  end

  def authenticate!
    u = Wippr::User::Account.authenticate(params["email"], params["password"])
    u.nil? ? fail!("Could not log in") : success!(u)
  end
end



# Kick things off
require 'app/wippr'
run Wippr::Application
