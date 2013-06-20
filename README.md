RiveScript::HTTPd
=================

INTRODUCTION
------------

RiveScript::HTTPd is a simple Python HTTP daemon intended for quickly being able
to test and develop web-based RiveScript chatbots. Simply running the
`rivescript-httpd.py` application and navigating to the URL it points out
should be enough to get up and running immediately.

From the home page of the web site the daemon runs, there (will be) links to
launch a chat session with either a CGI based RiveScript bot (powered by either
Perl or Python), or a client side JavaScript-powered bot.

*NOTE:* This project is still in early development and not everything mentioned
in this README document is true yet. ;)

CGI SUPPORT
-----------

The daemon supports the execution of CGI scripts, with support for Perl and
Python built in.

If you have a Perl or Python interpreter installed on your system, the daemon
should be able to make use of them to execute CGI scripts that call for the
respective programming language. Otherwise, the scripts won't be able to run,
and will present a friendly error page instead that explains what you can do
to correct the problem.

If you don't have a Python interpreter installed (for example, if you're running
the daemon from a pre-compiled `.exe` binary), the daemon itself will attempt to
execute the Python CGI scripts. This should work fine for the scripts that ship
with the daemon, because they don't include any third-party modules that the
daemon itself doesn't also include. Running other CGI scripts from the daemon's
document root may cause problems though.

DEPENDENCIES
------------

You'll want to `pip install rivescript` to get the Python CGI script to work,
and install the Perl RiveScript module to get the Perl script to work.

COPYRIGHT AND LICENSE
---------------------

	RiveScript::HTTPd
	Copyright (C) 2013 Noah Petherbridge

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

SEE ALSO
--------

The official RiveScript website, http://www.rivescript.com/
