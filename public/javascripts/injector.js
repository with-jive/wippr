/**
  Wippr::injector.js v0.0.1
**/

/** 
*   We use the Entry pattern to consolidate this script across 
*   the site and allow for simple behavior expansion.
*
*   Pages wishing to use a javascript hook simply define their own
*   page name variable (as a namespace) and handle their code branch here.
**/

// Application entry point.
// Maps the page type to the action behavior.
$(document).ready(function(){
    // handle notice transitions
    if(window.notice !== undefined){
        $("#notice").animate({'height':'60px'},400)
                .delay(2500).fadeOut();
    }
    
    // handle development console missing...
    // if (window.console == undefined){
    //         window.console = function(){}
    //         window.console.log = function(str){};
    //     }
    
    if(user_id !== ''){
      window.user = true; // set ugly global
    } else {
      window.user = false;
    }
    
    // avoid page undefined case
    if(window.page === undefined){
        window.page = "";
    }
    // start branch
    switch(page){
        case "postnewtopic":
            initialise_post_new_topic_page();
            break;
        case "postdisplay":
            initialise_post_display_page();
            break;
        case "signup":
            initialise_signup();
            break;
    }
    
    
    // Run global page hooks,
    // aka site wide functionality
    runGlobalHooks();

});


// Site wide functionality hooks
function runGlobalHooks(){
    

    
    
    if(!user){
        // user is not signed in
        var signin_timer;
        
        $("#login .signin").click(function(){
            $("#signin-panel-container").animate({'top':'42px'}, 300,function(){
                $("#signin-panel-label").fadeIn();
                $("#close-signin-panel").fadeIn();
            });
            window.setInterval(function(){
              if(
                   (document.getElementById('signin-user').value.length > 3)
                && (document.getElementById('signin-password').value.length > 3)
                ){
                  $("#signin-panel-shim").hide();
                }else {
                  $("#signin-panel-shim").show();
                }
            },200);
            
        });
        $("#close-signin-panel").click(function(){
            $("#close-signin-panel").hide();
            $("#signin-panel-label").hide();
            $("#signin-panel-container").animate({'top':'-100px'}, 300);
        });
        
        $("#signin-submit").click(function(){
          
        });
        
        // hook oauth buttons
        $("#fb-button").click(function(){
          window.location = "/auth/facebook";
        });
        
    } else {
      // User is signed in

      
      // hook user popups
      $("#email").hover(
        function(){popup("email")}, 
        function(){popout("email")});
      $("#settings").hover(
        function(){popup("settings")}, 
        function(){popout("settings")});
      $("#logout").hover(
        function(){popup("logout")}, 
        function(){popout("logout")});
      
      $("#email").click(function(){
        popout("email");
        openMail();
      });
      $("#settings").click(function(){
        //popout("settings");
        //openSettings();
      });
         
      // menu hover helpers
      function popout(id){
        $("#" + id + "-popup").hide();
      }
      function popup(id){
        $("#" + id + "-popup").show();
      }   
      
    }
    
    $("#close-management").click(function(){
      closeManagerBox();
    });
    

}

// Signup Page
function initialise_signup(){


    window.setInterval(function(){
        var username = document.getElementById('signup-username').value;
        var email = document.getElementById('signup-email').value;
        var password = document.getElementById('signup-password').value;
        var password_conf = document.getElementById('signup-password-conf').value;
        
        var esuccess = false;
        var psuccess = false;
        var usuccess = false;

        if(email.length > 5){
            if(emailValidator(email)){
                $(".email-validation .signup-check").show();
                $(".email-validation .signup-x").hide();
                esuccess = true;
            }
        }else {
            $(".email-validation .signup-check").hide();
            $(".email-validation .signup-x").show();
            esuccess = false;
        }


        if(username.length > 3) {
            usuccess = true;
        } else {
            usuccess = false;
        }


        if(password.length > 4){
            if(password == password_conf){
                psuccess = true;
                $(".password-validation .signup-check").show();
                $(".password-validation .signup-x").hide();
            } else {
                $(".password-validation .signup-x").show();
                $(".password-validation .signup-check").hide();
                psuccess = false;
            }
        }


        if(psuccess && esuccess && usuccess){
            $("#submit-button").attr('disabled', '');
            $("#signup-shim").fadeOut();
        } else {
            $("#submit-button").attr('disabled', 'disabled');
            $("#signup-shim").show();
        }



    }, 350);

}

// Posting a new topic post, spice up the page
function initialise_post_new_topic_page() {
    $("#postTextBox").ckeditor(function(){},
        {toolbar : [
            ['Styles', 'Format'],
            ['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', '-', 'Image']
        ], height: '100%', toolbarCanCollapse:false, resize_enabled:false});
        


    $("#postSubmitButton").button();

// END initialise_post_new_topic_page();        
}


// Viewing a Post. We hook the reply button behavior
function initialise_post_display_page() {

    // temporary preview template
    var messageInject = "" +
      "<div class='message'> " +
        "<div class='author'> " +
          "<div class='title'> " +
            "<a href='[id]'>[handle]</a>" +
          "</div>"  +
          "<div class='avatar'>" +
            "<img class='avatar-image' src='[avatar_url]' />" +
            "<img class='avatar-cutoff' src='/images/avatar_cutoff.png' />" +
          "</div>"  +
        "</div> " +
        "<div class='backer'></div>" +
        "<div class='updated_at'> "  +
          "[date]" +
        "</div> " +
        "<div class='body' id='reply-preview-body'>" +
        "</div> " +
      "</div>";
    
    var currentScroll; // scrollTop tracker
    var trans = false; // transitioning flag
    var replyBox = false;
    var isHuge = false;


    // Hook the textarea
    var textarea = document.getElementById('reply-textarea');
    var previewContainer = document.getElementById('reply-preview-container');
    previewContainer.innerHTML = generateMessage();
    var messageContainer = document.getElementById('reply-preview-body');
    var replyDone = false;


    
    $('#reply-textarea').ckeditor(function(){},
        {toolbar : [
            [ 'Format'],
            ['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', '-', 'Image']
        ], height: '100%', toolbarCanCollapse:false, resize_enabled:false, ImageButton: true});


    window.setInterval(function(){
        if(!replyDone){
            messageContainer.innerHTML =
            $('#reply-textarea').val();
        }
    }, 500);

    

    // attach click handlers
    $("#reply-close-button").click(function(){
            closeReplyBox();
            // Check for possibility that we were huge while closing
            // So we must do a adhoc shrinkage, NOT a full shrinkMe()
            if(isHuge){
                isHuge = false;
                document.getElementById("huge-button").innerHTML = "MAKE ME HUGE";
                // $("#reply-textarea").animate({
                //     'height':'165px'
                // }, 300);
            }
    });
    $("#reply-button").click(function(){
        if(trans){ return; }
        currentScroll = $(window).scrollTop();
        openReplyBox();
    });//end openReplyBox
    $("#huge-button").click(function(){
        if(trans) {return;}
        currentScroll = $(window).scrollTop();
        if(!isHuge){
            growHuge(currentScroll);
        } else {
            shrinkMe(currentScroll);
        }
    });
    $("#reply-submit-button").click(function(){
        if(trans){console.log("still in motion...");return;}
        var content = "";        
        content = $('#reply-textarea').val();

        if (content === "") {
            console.log("Could not find text input...");
        } else {
            var url = root + forum_name + "/" + post_id + "/new";
            console.log("Posting reply to server...\n" + url);
            // We got content to post!


            $.post(url, // post specific url
            { // content hash
                'reply-content': content,
                'reply-postid': post_id,
                'reply-posttitle': post_title
            },
                  function(data) {
                      handleResponse(data);
                  } // response handler
                    );

            waitForResponse();

        }
    });
        
    function openReplyBox() {
        trans = true;
        $("#reply-box").show();

        $("#reply-box").animate({
            'height':'200px'
        },300, function(){$(".reply-content").show();});
        $("html,body").animate({scrollTop: currentScroll + 1000}, 500, function(){trans=false;});


        $("#huge-button").show();
        $("#reply-submit-button").show();
        $("#reply-button").hide();
        $("#reply-close-button").show();
        $(".reply-content").css({opacity: '1'});
        $("#reply-preview-container").css({opacity: '0.4'});
        $("#reply-preview-container").toggle();

        $(".cke_contents").css({height:'130px'});


    }
    function closeReplyBox() {
        $("#reply-preview-container").toggle();
        $("#reply-preview-container").css({opacity:0});
        $("#reply-button").css("background", "none");
        $("#reply-box").animate({'height':'0px'},500);
        $("#reply-button").css("color", "");
        $("#huge-button").hide();
        $(".reply-content").css({'opacity': 0});
        $("#reply-submit-button").hide();
        $("#reply-button").show();
        $("#reply-close-button").hide();
    }
    function disableReplyBox() {
        $("#reply-box").animate({
            'height':'0px'
        },300, function(){
            trans = false;
        });
        $("#huge-button").hide();
        $(".reply-content").css({'opacity': 0});
        $("#reply-submit-button").hide();
        $("#reply-close-button").hide();
        replyDone = true;
        document.getElementById('reply-box').innerHTML = "<span class='reply-success'>Reply Posted Successfully :)</span>";
    }

    function waitForResponse(){
        $("#reply-cover").toggle();
    }
    function handleResponse(data){

        if (data === "success") {
          console.log("success");
          $("#reply-cover").fadeOut();
          disableReplyBox();
          $("#reply-preview-container").animate({opacity:1},500);
            
        } else if (data === "fail") {
          console.log("Fail!");
          console.log(data);
        } else {
          console.log("FAIL \n" + data);
        }
    }
    function handleEditResponse(data, content, msg_id){
      // console.log("Data received: " + data + "\n END \n "); //debugging
      if(data.indexOf('success') >= 0){
        console.log('update success');
        $("." + msg_id + " .body").html(content);
        $(".edit-overlay").fadeOut();
        
      }
    }

    // Hook user control functionality
    // note: permissions are enforced serverside   
    if (user) {
      $("." + user_id).toggle(); // show the controls related to the current user
      
      // hook the edit buttons to the edit action
      $("." + user_id + " .edit").each(function(index, value){
        // We need to reach up two levels to get the [message] object,
        // then we can extract the message ID from the class name for 
        // future operations
        var msg_id = value.parentNode.parentNode.className.replace("message", "");
        msg_id = msg_id.replace(" ", ""); //clear spaces
        // now we hook the click to the action handler with the appropiate
        // IDs wrapped in the function closure
        $(value).click(function(){
          editMessage(msg_id);
        });
      });
      // hook the delete buttons to the delete action
      $("." + user_id + " .delete").each(function(index, value){
        // We need to reach up two levels to get the [message] object,
        // then we can extract the message ID from the class name for 
        // future operations
        var msg_id = value.parentNode.parentNode.className.replace("message", "");
        msg_id = msg_id.replace(" ", ""); //clear spaces
        // now we hook the click to the action handler with the appropiate
        // IDs wrapped in the function closure
        $(value).click(function(){
          deleteMessage(msg_id);
        });
      });
    }
    
    
    function editMessage(msg_id){
      console.log("Editing message: " + msg_id);
      var id_gen = msg_id+"_editor_" + Math.floor(Math.random()*1000);
      var url = "/" + forum_name + "/" + post_id + "/" + msg_id + "/update";
      var save = document.createElement("div");
      var cancel = document.createElement("div");

      
      save.className = "saveButton";
      cancel.className = "cancelButton";
      
      var editorContainer = document.createElement("div");
      editorContainer.className = "edit-overlay";
      
      var editor = document.createElement("div");
      editor.className = "edit-editor";
      
      editor.id = id_gen;

      editorContainer.appendChild(editor);
      editorContainer.appendChild(save);
      editorContainer.appendChild(cancel);
      
      var containerElement = $("." + msg_id + " .body")[0];
      var content = containerElement.innerHTML;
      
      containerElement.appendChild(editorContainer);
      $(editorContainer).fadeIn();
      // Create the editor
//      $(editor).ckeditor(function(){
//          this.setData(content);
//          editorInstance = this;},
//        );
        // handle cleanup of any previous editors first

        var editorInstance = CKEDITOR.replace(id_gen,
        { toolbar : [['Format'],
        ['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', '-', 'Image']
        ], height: '100%', toolbarCanCollapse:false, resize_enabled:false, ImageButton: true});

        editorInstance.setData(content);
      
      $(cancel).click(function(){
        $(editorContainer).fadeOut();
        // cleanup the temporary editor instance
        CKEDITOR.instances[id_gen].destroy();
//          containerElement.removeChild(editorContainer);
      });
      $(save).click(function(){
        var content =  editorInstance.getData();
        console.log("pushing update : \n" + content);
        $.post(url, // post specific update url
            { // content hash
                'message-content': content
            },function(data){
              handleEditResponse(data, content, msg_id);
            });
      });
    
      
    }
    
    function deleteMessage(msg_id){
      console.log("Deleting message: " + msg_id);
        var conf = confirm("Delete this post?");
        if(conf){
          $("." + msg_id).fadeOut();
          var delete_url = root + forum_name + "/" + post_id + "/" + msg_id + "/" + "delete";
          $.post(delete_url, {}, function(data){
              console.log(data);
          });
        }
    }
    
    

    // scoped helpers
    function generateMessage(){
        // build up our template injection
        var parsedMessage = messageInject.replace("[id]", user_id);
        parsedMessage = parsedMessage.replace("[handle]", user_handle);
        parsedMessage = parsedMessage.replace("[avatar_url]", avatar_url);
        parsedMessage = parsedMessage.replace("[date]", '');
        return parsedMessage;

    }
    function growHuge(currentScroll) {
        trans=true;
        $("#reply-box").animate({'height':'530px'},300);
        $("html,body").animate({scrollTop: currentScroll + 1200}, 500, function(){
            trans=false;
        });
        
        document.getElementById("huge-button").innerHTML = "SHRINK ME";
        isHuge = true;

    }
    function shrinkMe(currentScroll) {
        $("#reply-box").animate({'height':'200px'}, 300);
//        $("html,body").animate({scrollTop: currentScroll + 500}, 500, function(){});
        document.getElementById("huge-button").innerHTML = "MAKE ME HUGE";
        isHuge = false;
    }





    


// END initialise_post_display_page();   
}



// Global Helpers
function emailValidator(email){
    regex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
    return regex.test(email);
}

















