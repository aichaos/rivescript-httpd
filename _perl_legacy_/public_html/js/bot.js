/* Main JavaScript for the RiveScript::HTTPd JS Bot */

var RS;

function rs_addlog (mess, reply) {
	var user = $("<div>");
	var bot  = $("<div>");
	user.html("<span class='client'>You:</span> " + mess);
	bot.html("<span class='robot'>" + rs_settings.bot_name + ":</span> " + reply);
	$("#history").append(user).append(bot);
	$("#dialogue").animate({ scrollTop: $("#history")[0].scrollHeight }, 1000);
}

$(document).ready(function() {
	// Debug mode
	var debugMode = false;
	if (window.location.search.indexOf("debug=1") > -1) {
		debugMode = true;
	}

	// Initialize the bot.
	RS = new RiveScript({
		debug:     debugMode,
		debug_div: "rs_debug"
	});

	// File list.
	var files = [];
	for (var i = 0; i < rs_filelist.length; i++) {
		files.push( rs_settings.brain_path + "/" + rs_filelist[i] );
	}

	RS.loadFile(files, function(batch_num) {
		// Loading successful. Sort the replies.
		RS.sortReplies();

		// Welcome message.
		if (rs_settings.welcome) {
			var mess = $("<div>");
			mess.html("<span class='robot'>" + rs_settings.bot_name + ":</span> " + rs_settings.welcome);
			$("#history").append(mess);
		}

		// Configure all the hooks.
		$("#chatform").submit(function (ev) {
			var mess = $("#message").val();
			$("#message").val("");

			var reply = RS.reply("user", mess);
			rs_addlog(mess, reply);

			ev.preventDefault();
			return false;
		});
	}, function(batch_num, error) {
		// Loading error!
		window.alert("Error when loading files: " + error);
		$("#message").attr("disabled", true);
		$("#submit").attr("disabled", true);
	});

	$("#message").focus();
});
