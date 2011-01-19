var management = {
    open : false,
    currentPane : "none",
    mailMarkup : false,
    settingsMarkup : false,
    currentView : "none",
    lastSize : 0,
    sizeRunning : false,
    composeEditor : false

};


/****************************************
 * Mail Management
 * *************************************/
function openMail() {
    // open view if not already open
    if (!management.open) {
        openManagerBox();
    }

    if (management.mailInitialiser === undefined) {
        management.mailInitialiser = function() {
            console.log("Initialiser called!");
            // set our initial view
            openView("inbox");

            var currentView = management.currentView;

            try {
                $(".mm-active-mail").removeClass("mm-active-mail");
                $(".mm-inbox").addClass("mm-active-mail");
            } catch(e) {

            }

            try {
                management.composeEditor = CKEDITOR.replace("mail-compose-editor",
                { toolbar : [
                    ['Format'],
                    ['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', '-', 'Image']
                ], height: '100%', toolbarCanCollapse:false, resize_enabled:false, ImageButton: true});
            } catch(e) {
            }

            if (management.sizeRunning === false) {
                management.sizeRunning = window.setInterval(function() {
                    autoContainerSize();
                }, 600);
            }

            runMailHooks();
        }
    }

//    if (management.currentPane === "mail") return;

    loadMarkup("mail");
    management.currentPane = "mail";
    
    // open view if not already open


}

function runMailHooks(){
            // hook our menu buttons
            $(".man-menu").click(function() {
                var view = management.currentView;
                var inner = this.innerText;
                openView(inner);
                autoContainerSize();
                if (view !== inner) {
                    try {
                        $(".mm-" + view).removeClass("mm-active-mail");
                        $(".mm-" + inner).addClass("mm-active-mail");
                    } catch(e) {
                    }
                }
            });
            // hook our mail item readers
            $(".mail-item").click(function(){
                if(this.className.indexOf("preset") >= 0){
                    console.log("preset detected");
                    return;
                }

                startMailReader(this.id);
                openView("reader");

            });
            // hook our compose send button
            $("#compose-sendbutton").click(function() {
                var subject = document.getElementById("compose-subject").value;
                var towho = document.getElementById("compose-recipient").value;
                var body = management.composeEditor.getData();
                $("#compose-wrapper").fadeOut();
                $("#compose-spinner").fadeIn();

                $.post("/user/mail/send",
                {'towho':towho, 'subject':subject, 'body':body},
                      function(data) {
                          var result = $.parseJSON(data);
                          console.log(result);
                          if (result.success === true) {
                              //                    $("#compose-wrapper").fadeIn();
                              $("#compose-spinner").fadeOut();
                              $("#compose-wrapper").delay(1500).fadeIn();
                              $("#compose-message-container").html(
                                      "<h1>Message sent successfully!</h1> <p> A copy is stored in your outbox</p>")
                                      .delay(2000).fadeOut();
                              addToOutBox(subject, towho, result.letter_id, result.date);
                          } else {
                              $("#compose-message-container").html(result.error);
                              $("#compose-wrapper").fadeIn();
                              $("#compose-spinner").fadeOut();
                          }
                      });

            });
}

function startMailReader(id){
    $(".mm-active-mail").removeClass("mm-active-mail");
    console.log(id);
    $("#reader-container").hide();
    $("#reader-spinner").fadeIn();
    var url = "/user/mail/view/" + id;
    $.get(url, function(data){
        var result = $.parseJSON(data);

        if(result.unread){
            markMessageAsRead(id);
        }

        $(".reader .from").html(result.from);
        $(".reader .recipient").html(result.to);
        $(".reader .msg-subject").html(result.subject);
        $(".reader .msg-body").html(result.message);
        $(".reader .msg-date").html(result.date);
        $("#reader-container").fadeIn();
        $("#reader-spinner").hide();
    });
}
function markMessageAsRead(msg_id){
    console.log("marking as read");
    $.get("/user/mail/markread/" + msg_id, function(data){});
    $(".inbox #" + msg_id).removeClass("unread");
}


/****************************************
 * User Settings Management
 * *************************************/

function openSettings() {
    loadMarkup("settings");

    // open view if not already open
    if (!management.open) {
        openManagerBox();
    }

}


/****************************************
 * Management Helpers
 * *************************************/

function addToOutBox(subject, to, id, date) {
    // hide any existing default messages
    try {
        $(".preset-outbox-item").remove();
    } catch(e) {
    }

    var template_html = "<div id='{id}' class='mail-item'><div class='subject'>{subject}</div><div class='to'>{to}</div><div class='date'>{date}</div></div>";
    template_html = template_html.replace("{id}", id);
    template_html = template_html.replace("{to}", to);
    template_html = template_html.replace("{subject}", subject);
    template_html = template_html.replace("{date}", date);

    var current_html = $(".outbox .mail-items").html();
    $(".outbox .mail-items").html(current_html + template_html);
    updateMarkupCache();

}


/** Fetches the html markup for a given view
 * and then feeds it into the view/ data is cached
 *
 * @param {String} type This is the view type
 * @param {Function} callback A callback hook for xhr data completion
 */
function loadMarkup(type) {
    // clear any previous views

    if(management.currentPane === type) return;
    // used cached markup if available
    if (management[type + 'Markup'] === false) {
        console.log("First load!");

        // grab mail markup and store it
        $.get("/user/" + type, function(data) {
            management[type + 'Markup'] = data;
            $("#management").html(data);
            management[type + "Initialiser"]();
        });
    } else {
        $("#management").html(management[type + 'Markup']);
    }


}

/** Update the markup cache
 * Used when the markup is modified or updated
 */
function updateMarkupCache() {
    management[management.currentPane + "Markup"] = $("#management").html();
    runMailHooks();
}

function openView(name) {
    // hide any existing views
    if (management.currentView !== name) {

        $("#man-view ." + management.currentView).hide();
        // show our inbox view
        management.currentView = name;
        $("#man-view ." + name).show();
        resizeManagerContainer(250);
    } else {
        $("#man-view ." + name).show();
        //resizeManagerContainer(200);
    }


}

function openManagerBox() {
    management.open = true;
    //resizeManagerContainer(200);
    $("#welcome").fadeOut();
    $("#close-management").fadeIn();
    $("#management").fadeIn();
}

function closeManagerBox() {
//    CKEDITOR.instances["mail-compose-editor"].destroy();

    management.open = false;
    //management.currentPane = "";
    resizeManagerContainer(42);
    $("#welcome").fadeIn();
    $("#close-management").fadeOut();
    $("#management").fadeOut();
}

function autoContainerSize() {
    var view = management.currentView;

    if (view === "none") return;
    if (!management.open) return;

    var height = $("#man-view ." + view)[0].offsetHeight + 100;
    if (height < 250) height = 250;
    resizeManagerContainer(height);
}

function resizeManagerContainer(size) {
    if (size === management.lastSize) {
        return;
    }
    management.lastSize = size;
    $("#navbar").animate({height:size + 'px'}, 200);
    $("#management").animate({height:size + 'px'}, 200);
}
