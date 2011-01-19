module Wippr
  module Core
    def self.registered(app)
      
      # Front Forum index
      app.get "#{$forum_mount}" do
        @forums = Wippr::Forum.by_order
#        flash[:notice] = "Testing"
        render :haml, :"forums/forum_index"

      end


      app.get "/unauthenticated/?" do
        redirect link_for_login
      end

      # --------------------------------------------
      # Display Index of existing Posts for a Specific Forum
      # --------------------------------------------
      app.get "#{$forum_mount}:forum/?" do
        # Get both a canonical and pretty version of the _id
        @forum_name = params[:forum].to_s.gsub "-", " "
        @forum_id = params[:forum].to_s

        @posts = Wippr::Post.by_forum_id_and_created_at(
                :startkey => [@forum_id, "3"],
                :endkey => [@forum_id, "1"]
        )
        render :haml, :"forums/forum_show"
      end

      # --------------------------------------------
      # Attempt to create a Post in a specified Forum
      # --------------------------------------------
      app.get "#{$forum_mount}:forum/new/?" do
        authorize!
        @post = Wippr::Post.new
        @forum_name = params[:forum]
        render :haml, :"posts/posts_new"
        
      end

      # --------------------------------------------
      # Create a new Post in a specified Forum
      # --------------------------------------------
      app.post "#{$forum_mount}:forum/create/?" do
        authorize!
        # Determine which handle to use for this user
        # As it varies between Facebook users and userid users
        author_handle = get_user_handle #implicit user_id OR first_name + last_name[0]
        author_id = current_user.handle #explicit user_id
        @forum_name = params[:forum]

        post = Wippr::Post.new
        post.forum_id = @forum_name
        post.title = params[:title]
        post.slug
        post.author_handle = author_handle
        post.last_author_handle = author_handle
        post.last_author_id = author_id

        forum = Wippr::Forum.by__id(:key => @forum_name).first
        forum.update_view get_the_date, author_handle, post.title
        

        message = Wippr::Message.new
        message.forum_id = @forum_name
        message.post_title = post.title
        message.post_id = post.slug
        message.author_handle = author_handle
        message.author_id = author_id
        message.avatar_url = current_user.avatar
        message.message = params[:body]
        message.root = true
        
        backurl = "/#{@forum_name}/new"
        
        
        begin
          if message.save!
            if post.save!
              forum.save!
              flash[:notice] = "Post created successfully!"
              redirect link_for_forum @forum_name
            end
          end
        rescue
          backurl = "/" + @forum_name + "/new"
          render :haml, :"posts/posts_create"
        end

      end

      # --------------------------------------------
      # Display Messages of a specific Post
      # --------------------------------------------
      app.get "#{$forum_mount}:forum/:post/?" do
        unless current_user.nil?
          @author_id = current_user.handle
          @author_handle = get_user_handle
          @avatar_url = current_user.avatar
        end
        
        post = params[:post]
        @forum_name = params[:forum]
        # Fetch messages with reverse sorting keys
        @messages = Wippr::Message.by_post_id_and_created_at(:startkey => [post, "1"],:endkey => [post, "3"])
        @root = "/"
        @post_title = @messages[0].post_title
        @post_id = @messages[0].post_id
        render :haml, :"posts/posts_show"
      end

      # --------------------------------------------
      # Delete a specified Forum post, along with all it's messages
      # --------------------------------------------
      app.get "#{$forum_mount}:forum/:post/delete/?" do
        authorize!

        post = Wippr::Post.by_slug(:key => params[:post].to_s).first

        if current_user.isAdmin?
          post.delete_post_and_messages!
        end

        redirect link_for_root + params[:forum]
      end

      # --------------------------------------------
      # DELETE a specific individual message
      # !This is handled asyncronously via clientside XHR
      # --------------------------------------------
      app.post "#{$forum_mount}:forum/:post/:message/delete/?" do
        puts "Deleting message!"
        success = false
        root = false
#        begin
          message = Wippr::Message.get(params[:message])
          if message.nil?
            raise "Nil Message | Fail"
          end
          author_id = message.author_id
          post = Wippr::Post.by_slug(:key => message.post_id).first
          
          # message is a root post message, so we must delete all messages beneath it
          if message.root
            post.delete_post_and_messages!
            # return and tell client that we deleted a root
            # (client should redirect the page to the index)
            root = true
          else
            # not a root message, so just delete itself and nothing else
            message.destroy
            
            # Trigger view dependency updates~ given the old author,
            # this will climb up the chain to the root forum.
            # Updating each statistic after saving itself
            post.decrement_replies
            post.update_post_author! author_id
            post.save!
          end
          success = true
#        rescue
#          puts "Operation Failure"
#          success = false
#          puts $!.to_s
#        end


        # response branching: we will let the client parse this to decide if
        # it should redirect to the forum index if root=true
        if success
          if root
            halt 200, {'Content-Type' => 'text/plain'}, 'success root'
          else
            halt 200, {'Content-Type' => 'text/plain'}, 'success'
          end
        else
          puts "Message Deletion FAIL!"
          halt 200, {'Content-Type' => 'text/plain'}, 'fail' + $!.to_s
        end

      end
      
      
      
      # --------------------------------------------
      # UPDATE a specific individual message
      # !This is handled asyncronously via clientside XHR
      # --------------------------------------------
      app.post "#{$forum_mount}:forum/:post/:message/update/?" do
        authorize!
        
        msg_id = params[:message]
        message_content = params["message-content"]
        puts message_content
        message = Wippr::Message.get(msg_id)
        message.message = message_content
        
        # Make sure user is either the original author or admin
        if current_user.handle != message.author_id
          if current_user.isAdmin?
            puts "admin editing..."
          else
            halt 200, {'Content-Type' => 'text/plain'}, 'fail : user authentication failed'
          end
        end
        
        # Begin, capture any failures
        begin
          message.save!
        rescue
          halt 200, {'Content-Type' => 'text/plain'}, 'fail : message not saved \n' + $!.to_s
        end
        
        # Success
        halt 200, {'Content-Type' => 'text/plain'}, 'success'
        
        
      end
      
      # --------------------------------------------
      # CREATE a reply to an existing post within a forum
      #
      # Returns 'success' on a successfully reply operation,
      # and 'fail' for failure. Currently not that robust for error
      # handling, but that should be delegated to the client side
      # --------------------------------------------
      app.post "#{$forum_mount}:forum/:post/new/?" do
        authorize!

        # preemptive response container
        xhr_response = "success"
        # Grab those values!
        content = params["reply-content"]
        post_id = params["reply-postid"]
        post_title = params["reply-posttitle"]
        forum_id = params[:forum]
        author_handle = get_user_handle
        author_id = current_user.handle

        # Make sure an empty message didn't slip in.
        # Then process it
        if content.nil? || content == ""
#          puts "\n fail:: no content \n"
          xhr_response =  "fail no content"
        else
          # Everything look good thus far,
          # Let's create our reply
          message = Wippr::Message.new

          # Update the view dependencies
          # both the parent post, and the container forum
          
          post = Wippr::Post.by_slug(:key => post_id).first
          post.last_author_handle = author_handle
          post.last_author_id = author_id
          post.author_id = author_id
          post.author_handle = author_handle
          post.increment_replies
          post.update_timestamp
          post.save!
          
          forum = Wippr::Forum.by__id(:key => forum_id).first
          forum.update_view get_the_date, author_handle, post.title
          forum.save!


          # get_user_handle returns either the handle or Firstname + Lastname[0]
          # Depending if the user is a Facebook user or a 'homebrew' user
          message.author_handle = author_handle
          
          message.author_id = author_id
          message.avatar_url = current_user.avatar
          message.forum_id = forum_id
          message.message = content
          message.post_id = post_id
          message.post_title = @post_title
          message.save!
        end

        # Just return our little response quickly
        halt 200, {'Content-Type' => 'text/plain'}, xhr_response
        
      end


    end
end
end
