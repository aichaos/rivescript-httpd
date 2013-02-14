#!/usr/bin/perl

# RiveScript::HTTPd Example Perl FastCGI Bot
#
# TODO: this script will be a FastCGI script ready to drop in to an existing
# Apache setup. It probably won't run on the rs-httpd server.

use 5.14.0;
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

if ($ENV{SERVER_SOFTWARE} eq 'RiveScript::HTTPd') {
	print "Content-Type: text/html\n\n";
	print "The RiveScript::HTTPd daemon doesn't support FastCGI scripts. "
		. "Upload this to an Apache server configured with mod_fcgid instead.";
	exit(0);
}
