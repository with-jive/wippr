module Wippr
  module AuthRoutes


    def self.registered(app)
      helpers Wippr::AuthHelpers
      
      app.get "/auth/:name/callback/?" do
        auth = request.env["omniauth.auth"]
#        auth["uid"].to_yaml
        case auth["provider"]
          when "facebook"
            puts "\n Looking for facebook user.. \n"
            @user = find_facebook_user auth["uid"]
            puts @user.to_s
            unless @user.nil?
              puts "\n User found \n"
              puts @user.handle + "\n"
              warden.set_user(@user)
            else
              puts "\n User not found \n"
              @user = create_facebook_user auth
              @user.save!
              warden.set_user(@user)
            end
            redirect "/"

        end
        
      end


    end
end
end
