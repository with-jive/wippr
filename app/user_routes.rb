module Wippr
  module UserRoutes

    #---------------------------------------------
    # User management routes
    #---------------------------------------------

    require 'digest/md5'
    require 'json'
    def self.registered(app)
      #helpers Wippr::UserHelpers

      app.get "/user/mail" do
        puts "mailbox : " + current_user.mailbox.to_s
        mailbox = Wippr::Mail::MailBox.by__id(:key => current_user.mailbox).first
        puts mailbox
        if mailbox.nil?
          raise "Mailbox nonexistant :("
        end
        @inbox = mailbox.inbox
        #puts "Inbox count \n #{@inbox.count}"
        render :erb, :"user/mail", :locals => {:inbox => mailbox.inbox, :outbox => mailbox.outbox}
      end

      # Create a new message and send it!
      # Returns a JSON object containing the result
      app.post "/user/mail/send" do
        to = params["towho"]
        subject = params["subject"]
        body = params["body"]

        date = get_the_date
        letter = Wippr::Mail::Letter.new
        success = true
        begin
          letter.body = body
          letter.subject = subject
          letter.from_user_id = current_user.handle
          letter.to_user_id = to
          letter.created_at = date
          letter.save!
          letter.send! current_user.mailbox
        rescue
          success = false
        end

        letter_id = letter.id

        if(success)
          result = {:success => success,
                    :towho => to,
                    :subject => subject,
                    :letter_id => letter_id,
                    :date => date,
                    :body => body}.to_json
        else
          result = {:success => false,
                    :error => "Sorry your message could not be sent, please try again!"}.to_json
        end

        halt 200, {'Content-Type' => 'text/plain'}, result

      end

      # read a specific message
      app.get "/user/mail/view/:message/?" do
        message = Wippr::Mail::Letter.get(params[:message])
        # todo: simple permissions check container on the model
        # spoofing is highly unlikely with couchdb GUIDs though
        
        # if message.hasAccess? current_user
        result = {:subject => message.subject,
                  :from => message.from_user_id,
                  :to => message.to_user_id,
                  :message => message.body,
                  :date => message.created_at,
                  :unread => message.unread
        }
        puts "returning message : " + result.to_yaml
        result.to_json
      end

      # Mark a message as read
      app.get "/user/mail/markread/:message/?" do
        message = Wippr::Mail::Letter.get(params[:message])
        message.unread = false
        message.update_read_dependency
        message.save!
      end
      
      app.get "/user/settings" do
        render :erb, :"user/settings"
      end

      # Display the signup form
      app.get "#{$forum_mount}signup/?" do

        render :haml, :"user/user_new",
               :locals => {:username_error => nil, :email_error=>nil, :email => "",:username => "",:password => "" }
      end

      # Process the signup validations
      # then create account and set the user into
      # the warden auth system
      app.post "#{$forum_mount}signup/?" do

        username = params["username"]
        email = params["email"]
        password = Digest::MD5.hexdigest(params["password"])
        username_error = ""
        email_error = ""
        success = false
        # todo:
        
        existing_user = Wippr::User::Account.by_handle(:key => username)
        if existing_user.empty?
            success = true
        else
            success = false
            username_error = "Sorry that username is already taken"            
        end
        
        existing_email = Wippr::User::Account.by_email(:key => email)
        if existing_email.empty?
            success = true
        else
            success = false
            email_error = "Sorry that email is already in use"
        end

        if success

            account = Wippr::User::Account.new(:handle => username, :password => password, :email => email)
            account.assignMailBox
            account.save!
            warden.set_user(account)
            set_flash "Welcome to WipNation!"
            redirect "/"
        end
        

        render :haml, :"user/user_new",
               :locals => {:username_error => username_error,
                           :email_error => email_error,
                           :email => email,
                           :username => username,
                           :password => password}

      end

      # Display the signin form
      app.get "#{$forum_mount}signin/?" do
        render :haml, :"sessions/sessions_new"
      end

      # Process the signin
      app.post "#{$forum_mount}signin/?" do
        id = params[:id]
        using_email = false
        # is an email? regex matcher
        regex = /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        
        if regex.match(id)
            using_email = true
        end
        
        # Branch on authentication token type,
        # either an email or a user handle
        if(using_email)
            if @user = Wippr::User::Account.by_email(:key => id).first
              if @user.password == Digest::MD5.hexdigest(params[:password])
                warden.set_user(@user)
                redirect "/"
              end
            end
        else
            if @user = Wippr::User::Account.by_handle(:key => id).first
              if @user.password == Digest::MD5.hexdigest(params[:password])
                warden.set_user(@user)
                redirect "/"
              end
            end
        end
        
        set_flash "Incorrect Login", true

        render :haml, :"sessions/sessions_new"
      end

      # Logout
      app.get "#{$forum_mount}logout/?" do
        warden.logout
        redirect link_for_root
      end


      
    end
end
end
