module Wippr
  module AuthHelpers

    def find_facebook_user uid
      @user = Wippr::User::Account.by_facebook_uid(:key => uid).first
    end

    def create_facebook_user auth
      @user = Wippr::User::Account.new
      @user.assignMailBox
      begin
        @id = auth["extra"]["user_hash"]["id"]
        @user.handle = @id
        @user.password = "_"
        @user.password_confirmation = "_"
        @user.facebook_uid = auth["uid"]
        @user.first_name = auth["user_info"]["first_name"]
        @user.last_name = auth["user_info"]["last_name"]
        @user.email = auth["extra"]["user_hash"]["email"]
        @user.avatar = "https://graph.facebook.com/#{auth["extra"]["user_hash"]["id"]}/picture?type=large"
      rescue
        puts "\n\n\n -------- \n - FACEBOOK HASH ERROR \n \n"
      end

      @user
    end
    
    def username_exists? username
        user = Wippr::User::Acount.by_handle(:key => username)

    end
    

  end

end
