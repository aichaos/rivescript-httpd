#!/usr/bin/perl
if ($ENV{SCRIPT_NAME} =~ /config\.pl$/) {
	print "Content-Type: text/html\n\n";
	exit(0);
}

# RiveScript::HTTPd Perl CGI Settings
{
	# The name your bot should appear as in the history window.
	bot_name => 'RiveScript',

	# A welcome message to be displayed immediately when the page loads
	welcome => "Hi there! I'm a RiveScript chatbot. Send me a message!",

	# The path to your RiveScript brain. On the demo web server, this is by default
	# kept in the "brain" directory one level above the "js" one. When you upload
	# this to your web host, you'll probably want to move it to be in the same
	# folder as the HTML page. Change this value to be simply 'brain' in this case.
	# NOTE: the rivescript-httpd server runs scripts using the server root as the
	# current path, so "./public_html/brain" is the path to the RS brain.
	brain_path => 'public_html/brain',
	# brain_path => 'brain',

	# Name of the session cookie.
	session_cookie => 'rssessid',

	# How to save user session info? Options include:
	# json:  store them in flat text files
	# mysql: store them in a MySQL database
	session_method => 'json',

	# How long to expire unused sessions, in seconds. Set to 0 to never remove sessions.
	session_expire_seconds => 60*60*24*30, # 30 days
	session_expire_mysql   => '30 DAY',    # MySQL date format for INTERVAL

	# For JSON session storage, the path to store session files.
	# NOTE: the rivescript-httpd server runs scripts using the server root as the
	# current path, so "./public_html/sessions" is used here.
	json_root => "public_html/sessions",

	# For MySQL session storage, the database information. You'll need to import
	# the SQL table schemas in advance before this will work.
	mysql_host     => 'localhost',
	mysql_database => 'rs_perl',
	mysql_user     => 'rshttpd',
	mysql_password => 'big_secret',
};
