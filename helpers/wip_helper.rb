module Wippr
  module Helpers
    

    def link_to(title, url)
      "<a href='#{url}'>#{title}</a>"
    end

    def notice
        notice = get_flash :notice
    end

    def alert
        notice = get_flash :alert
    end

    def set_flash msg, now=false
      if now
        flash.now[:notice] = msg
      else
        flash[:notice] = msg
      end
    end

    def get_flash type
      val = false
      unless flash[type].nil?
        val = flash[type]
      end
      val
    end

    

    def get_user_handle
        if current_user.facebook_uid.nil?
          return current_user.handle
        else
          if current_user.handle == current_user.facebook_uid
            return current_user.first_name.to_s + " " + current_user.last_name.slice(0).to_s
          else
            return current_user.handle
          end
        end
    end



    # Always asume to have a trailing slash
    def link_for_root
      "/"
    end


    def link_for_user user
      "#{link_for_root}user/#{user}"
    end

    def link_for_forum name
      link_for_root + name
    end

    def url_for_post id, slug
      link_for_root + id + "/" + slug
    end

    def url_for_post_delete id, slug
      link_for_root + id + "/" + slug + "/delete"
    end


    def link_for_login
      "/signin"
    end
    
    def link_for_logout
      "/logout"
    end

    def link_for_signup
      "/signup"
    end

    def date_formatter date
      date.strftime("%I:%M%p | %m/%d/%y")
    end

    def get_the_date
      date_formatter DateTime.now
    end

    def get_unread_messages
      unread = 0
      if !current_user.nil?
        mailbox = Wippr::Mail::MailBox.get(current_user.mailbox)
        unread = mailbox.unreads
      end
      unread
    end

  end

end
