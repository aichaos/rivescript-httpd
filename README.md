RiveScript HTTPd
================

INTRODUCTION
------------

rs-httpd is a simple HTTP daemon that powers two different kinds of
web-based chatterbots. It has limited support for running CGI scripts
(if you have an available Perl or Python interpreter, it can execute
these scripts, otherwise it will attempt to execute Perl scripts by
itself which may not work if the Perl script includes third party
modules).

DEPENDENCIES
------------

The following Perl modules are needed for the HTTP daemon to run:

	HTTP::Daemon
	RiveScript
	Tkx

COPYRIGHT AND LICENSE
---------------------

The Perl RiveScript interpreter is dual licensed as of version 1.22. For open
source applications the module is using the GNU General Public License. If
you'd like to use the RiveScript module in a closed source or commercial
application, contact the author for more information.

	RiveScript HTTPd
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
