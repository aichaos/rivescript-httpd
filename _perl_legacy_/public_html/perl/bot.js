/* Main JavaScript for the RiveScript::HTTPd Perl Bot */

var RS;

function rs_addlog (who, name, reply) {
	var line = $("<div>");
	line.html("<span class='" + who + "'>" + name + ":</span> " + reply);
	$("#history").append(line);
	$("#dialogue").animate({ scrollTop: $("#history")[0].scrollHeight }, 1000);
}

$(document).ready(function() {
	var ajax_reply = function (data) {
		$("#message").removeAttr("disabled");
		$("#message").focus();
		if (data["status"] === "ok") {
			rs_addlog('robot', data["name"], data["reply"]);
		} else {
			window.alert(data["error"]);
		}
	};

	// Get our welcome message.
	$.ajax({
		dataType: "json",
		url: "rivescript.pl",
		data: {
			welcome: "1"
		},
		success: ajax_reply
	});

	// Configure all the hooks.
	$("#chatform").submit(function (ev) {
		var mess = $("#message").val();
		$("#message").val("");
		$("#message").attr("disabled", "disabled");
		rs_addlog('client', "You", mess);

		$.ajax({
			dataType: "json",
			url: "rivescript.pl",
			data: {
				message: mess
			},
			success: ajax_reply
		});

		ev.preventDefault();
		return false;
	});

	$("#message").focus();
});
