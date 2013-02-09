package RiveScript::HTTPd;

use 5.16.0;
use strict;
use warnings;

our $VERSION = '0.01';

use HTTP::Daemon;
use HTTP::Status;
use URI::Escape;
use Template;

=head1 NAME

RiveScript::HTTPd - A simple HTTP daemon for testing RiveScript bots.

=head1 SYNOPSIS

  use RiveScript::HTTPd;

  my $daemon = RiveScript::HTTPd->new(
    address => '127.0.0.1',
    port    => 2001,
    docroot => './public_html',
  )->start();

=head1 DESCRIPTION

This module uses L<HTTP::Daemon> to create a simple HTTP server intended for
testing RiveScript chatterbots.

It has limited support for executing CGI scripts. The shebang line of the CGI
script is read to look for an interpreter. If there is no Perl interpreter
installed to run a Perl (C<.pl>) script, the daemon will attempt to execute the
script directly. This will probably not work if the script has dependencies on
third-party modules that the daemon itself doesn't include.

=head1 METHODS

=head2 new (hash options)

Create a new HTTP daemon. You should generally only need one of these. Options
include:

  bool   debug:   Debug mode (prints a lot of stuff to the terminal).
  string address: The address to listen on. Default is 127.0.0.1
  int    port:    The port to listen on. Default is 2006

In addition, any of the L<"OPTIONS"> can be passed here as well.

By default, the daemon will print access log information to the terminal. Debug
mode makes it print additional information useful for development.

=cut

sub new {
	my $class = shift;
	my %opts  = @_;

	# Constructor options.
	my $self = {
		debug   => delete $opts{debug}   || 0,
		address => delete $opts{address} || '127.0.0.1',
		port    => delete $opts{port}    || 2006,
		daemon  => undef,
		interp  => {}, # Map of "found" interpreters.
		config  => { # Default options.
			# Daemon options.
			document_root   => './public_html',
			directory_index => [ 'index.cgi', 'index.pl', 'index.html', 'index.htm' ],
			show_indexes    => 1,
			cgi_scripts     => [ '.cgi', '.pl' ],

			# MIME types.
			'.html'    => 'text/html',
			'.htm'     => 'text/html',
			'.text'    => 'text/plain',
			'.txt'     => 'text/plain',
			'.asc'     => 'text/plain',
			'.css'     => 'text/css',
			'.js'      => 'text/javascript',
			'.dtd'     => 'text/xml',
			'.xml'     => 'text/xml',
			'.gif'     => 'image/gif',
			'.png'     => 'image/png',
			'.jpg'     => 'image/jpeg',
			'.jpeg'    => 'image/jpeg',
			'.jpe'     => 'image/jpeg',
			'.xbm'     => 'image/x-xbitmap',
			'.xpm'     => 'image/x-xpixmap',
			'.ico'     => 'image/x-icon',
			'.mp3'     => 'audio/mpeg',
			'.m3u'     => 'audio/x-mpegurl',
			'.wma'     => 'audio/x-ms-wma',
			'.wax'     => 'audio/x-ms-wax',
			'.ogg'     => 'application/ogg',
			'.wav'     => 'audio/x-wav',
			'.mpeg'    => 'video/mpeg',
			'.mpg'     => 'video/mpeg',
			'.mov'     => 'video/quicktime',
			'.qt'      => 'video/quicktime',
			'.avi'     => 'video/x-msvideo',
			'.asf'     => 'video/x-ms-asf',
			'.asx'     => 'video/x-ms-asf',
			'.wmv'     => 'video/x-ms-wmv',
			'.zip'     => 'application/zip',
			'.pdf'     => 'application/pdf',
			'.gz'      => 'application/x-gzip',
			'.tar.gz'  => 'application/x-tgz',
			'.tgz'     => 'application/x-tgz',
			'.tar'     => 'application/x-tar',
			'.gz2'     => 'application/x-bzip',
			'.tar.bz2' => 'application/x-bzip-compressed-tar',
			'.tbz'     => 'application/x-bzip-compressed-tar',
		},
	};
	bless $self, $class;

	# Pull additional options.
	foreach my $option (keys %opts) {
		$self->set_option($option, $opts{$option});
	}

	# Start the daemon.
	$self->{daemon} = HTTP::Daemon->new(
		LocalAddr => $self->{address},
		LocalPort => $self->{port},
		ReuseAddr => 1,
		Timeout   => 0.1,
	);

	return $self;
}

sub debug {
	my ($self, $message) = @_;
	return unless $self->{debug};
	say STDERR "[rshttpd] $message";
}

=head2 void set_option (string option, value)

Set an option for the HTTP daemon. The C<option> is always a string key, but
the C<value> may vary depending on the option. Most of the time it will be
a string, but sometimes it will be an array reference. See L<"OPTIONS"> for
the full list of options and their default values.

=cut

sub set_option {
	my ($self, $option, $value) = @_;
	$self->{config}->{$option} = $value;
}

=head2 data get_option (string option)

Retrieve the current value of C<option>.

=cut

sub get_option {
	my ($self, $option) = @_;
	return $self->{config}->{$option};
}

=head2 hashref get_options ()

Retrieve all of the options at once. The keys in the returned hash will be
the option keys.

=cut

sub get_options {
	my ($self) = @_;
	return $self->{config};
}

=head2 string url ()

Get the URL where the daemon can be accessed from, in the format
C<http://host:port/>

=cut

sub url {
	my ($self) = @_;
	return $self->{daemon}->url;
}

=head2 string find_interpreter (string name, string common_path, [check_paths] )

Call this method to "help" the daemon find interpreters to run CGI scripts with.
For example, most of the time the Python interpreter is in C</usr/bin/python>,
but on Windows platforms it would obviously be in a different location.

The consequence is that Python CGI scripts that begin with C<#!/usr/bin/python>
wouldn't run on a Windows system, even if Python is installed, because this HTTP
daemon would look for the shebang path literally.

This method can therefore allow the daemon to figure out the "real" location of
Python, and run that version instead of the one on the shebang path. Example:

  $d->find_interpreter("python", "/usr/bin/python");

Use the C<check_paths> option, an array reference, to provide a list of paths
to check. By default, if the C<common_path> doesn't exist on the local system,
the C<$PATH> will be searched to find the C<name>. If that doesn't work, then
the C<check_paths> list will be searched. Example:

  $d->find_interpreter("python", "/usr/bin/python", [
    'C:/Python/bin/python.exe',
  ]);

If the interpreter is found, it will be stored in memory associated with the
C<common_path>, so that if a CGI script attempts to use the C<common_path> in
its shebang line, the one found here will be used instead.

If it was found, this method returns the path. If not, it returns undef.

=cut

sub find_interpreter {
	my ($self, $name, $common_path, $check_paths) = @_;

	$self->debug("Attempting to find interpreter for $name...");
	my $found = "";

	# Is the common path there?
	if (-f $common_path) {
		# That was easy!
		$self->debug("Found $name at $common_path");
		$found = $common_path;
	} else {
		# Search $PATH for it.
		my @path = split(/[;:]/, $ENV{PATH});
		foreach my $dir (@path) {
			$self->debug("Searching $dir");
			if (-f "$dir/$name") {
				$self->debug("Found $name at $dir/$name");
				$found = "$dir/$name";
				last;
			} elsif (-f "$dir/$name.exe") {
				$self->debug("Found $name at $dir/$name.exe");
				$found = "$dir/$name.exe";
				last;
			}
		}

		# If not found, check the extra paths.
		if (!$found && ref($check_paths)) {
			foreach my $dir (@{$check_paths}) {
				if (-f $dir) {
					# Found it!
					$self->debug("Found $name at $dir");
					$found = $dir;
					last;
				} elsif (-d $dir && -f "$dir/$name") {
					# Found it here!
					$self->debug("Found $name at $dir/$name");
					$found = "$dir/$name";
					last;
				} elsif (-d $dir && -f "$dir/$name.exe") {
					# Found it here!
					$self->debug("Found $name at $dir/$name.exe");
					$found = "$dir/$name.exe";
					last;
				}
			}
		}
	}

	# Found? :(
	if ($found) {
		$self->{interp}->{$common_path} = $found;
		return $found;
	} else {
		return undef;
	}
}

=head2 void start ()

Starts an infinite loop of C<do_one_loop()>, for as long as C<do_one_loop()>
returns with a true value. Use this if you don't need another event loop
system in your daemon.

=cut

sub start {
	my ($self) = @_;

	while ($self->do_one_loop()) {
		# pass
	}
}

=head2 bool do_one_loop ()

Do one loop to accept and respond to incoming HTTP requests. This method
returns true as long as everything is still working properly. It will return
undef if some kind of error was encountered.

=cut

sub do_one_loop {
	my ($self) = @_;

	# Look for new requests.
	while (my $c = $self->{daemon}->accept) {
		while (my $r = $c->get_request) {
			# Basic request information.
			my $method  = $r->method;
			my $address = $c->peerhost;
			my $path    = $r->uri->path;
			my $query   = $r->uri->query;

			# Eventual return information.
			my $status        = RC_OK;
			my $content_type  = "text/plain";
			my $response_body = "";
			my $has_response  = 0; # This is 1 to indicate a good response for the user

			# Resolve the path to a file on disk.
			$self->debug("$address wants $path");
			my ($file,$uri) = $self->resolve_path($path);
			$self->debug("Resolved to local file: " . ($file ? $file : "(not found)"));
			$self->debug("Normalized URI path: $uri");

			# No local file? Give the 404 page if we can...
			if (!defined $file) {
				# Try the 404 page.
				$status = RC_NOT_FOUND;
				($file,undef) = $self->resolve_path("/errors/404.html");
			}

			# Don't allow digging around in the /errors/ folder.
			if ($uri eq "errors") {
				$status = RC_FORBIDDEN;
				($file,undef) = $self->resolve_path("/errors/403.html");
				$self->debug("Forbidding access to files under /errors URI.");
			}

			# Do we have a file to work with?
			if (defined $file && -f $file) {
				# Is it a CGI script?
				my $is_cgi = 0;
				foreach my $cgi_script (@{$self->{config}->{cgi_scripts}}) {
					if ($file =~ /\Q$cgi_script\E$/i) {
						$is_cgi = 1;
						last;
					}
				}

				# So, is it?
				if ($is_cgi) {
					$self->debug("File is a CGI script.");

					# We'll need to chdir to its directory.
					my $dirname = dirname($file);

					# Read its shebang line.
					open(my $peek, "<:utf8", $file);
					my $shebang = <$peek>;
					close($peek);
					$shebang =~ s/\s+.*?$//g; # Remove the cruft.
					$shebang =~ s/^#!//g;
					$self->debug("CGI interpreter: $shebang");

					# Found the interpreter?
					my $interpreter;
					if (-f $shebang) {
						$interpreter = $shebang; # Yes!
					} else {
						# It doesn't exist directly, but maybe we tracked it down elsewhere?
						if (exists $self->{interp}->{$shebang}) {
							# Brilliant!
							$interpreter = $self->{interp}->{$shebang};
						}
					}

					# Not yet?
					if (!$interpreter) {
						if ($shebang =~ /perl/) {
							# No Perl interpreter found, but we maybe able to run it ourselves!
							$interpreter = "_perl";
						} else {
							# No point in continuing then.
							$self->debug("The interpreter doesn't exist! 500 error...");
							$status = RC_INTERNAL_SERVER_ERROR;
							$content_type = 'text/html';
							$response_body = $self->render_template("$self->{config}->{document_root}/errors/interp.html", {
								file        => $file,
								interpreter => $shebang,
							});
							$has_response = 1;
						}
					}

					# OK to continue?
					if ($interpreter) {
						# Set up a standard CGI environment.
						local %ENV = (
							SCRIPT_NAME       => $uri,
							SCRIPT_FILENAME   => $file,
							SERVER_NAME       => "localhost", # TODO
							SERVER_ADMIN      => "root\@localhost", # TODO
							SERVER_ADDR       => $self->{address},
							SERVER_PORT       => $self->{port},
							DOCUMENT_ROOT     => $self->{config}->{document_root},
							REQUEST_METHOD    => $method,
							QUERY_STRING      => $query,
							GATEWAY_INTERFACE => 'CGI/1.1',
						);

						my $result; # The output of the CGI script.

						if ($interpreter eq "_perl") {
							# We'll try to execute the CGI script directly. But, we want to try to isolate
							# it from the rest of this module. So first, get its source code.
							local $/;
							open(my $contents, "<:utf8", $file);
							my $script = <$contents>;
							close($contents);

							my $sandbox = $self->make_sandbox();
							my $source = "package RiveScript::HTTPd::Sandbox::$sandbox;\n\n$script\n";
							$self->debug("Sandbox source:\n$source");

							my $stdout;
							local *STDOUT;
							open(STDOUT, ">", \$stdout);
							eval($source);

							# Errors?
							if ($@) {
								$self->debug("Errors: $@");
								$status = RC_INTERNAL_SERVER_ERROR;
								($file, undef) = $self->resolve_path("/errors/500.html");
								$is_cgi = 0;
							} else {
								$result = $stdout;
							}
						} else {
							$result = `$interpreter $file`;
							if ($?) {
								# Errors!
								$self->debug("Errors when executing the interpreter!");
								$status = RC_INTERNAL_SERVER_ERROR;
								($file, undef) = $self->resolve_path("/errors/500.html");
								$is_cgi = 0;
							}
						}

						if ($result) {
							# Parse the headers out.
							my @lines      = split(/\n/, $result);
							my $in_headers = 1;
							foreach my $line (@lines) {
								if (length $line == 0) {
									$in_headers = 0;
									next; # No more headers.
								}

								if ($in_headers) {
									my ($what, $is) = split(/\s*?:\s*?/, $line, 2);
									if ($what =~ /^content\-type$/i) {
										$content_type = $is;
									} elsif ($what =~ /^status$/i) {
										$status = $is;
									} else {
										# TODO: keep other headers
									}
								} else {
									$response_body .= "$line\n";
								}
							}

							$has_response  = 1;
						}
					}
				}

				if (!$is_cgi && $file) {
					# Just a mere mortal. Look up its MIME type.
					foreach my $mime_type (sort { length($b) <=> length($a) } grep { /^\./ } keys %{$self->{config}}) {
						if ($file =~ /\Q$mime_type\E$/i) {
							$content_type = $self->{config}->{$mime_type};
							last;
						}
					}

					# Get the contents of the file.
					local $/;
					my $mode = $content_type =~ /^text/ ? "<:utf8" : "<";
					open(my $contents, $mode, $file);
					binmode($contents);
					$response_body = <$contents>;
					close($contents);

					# The HTTP status should be 200 already, unless the 404 page changed it.
					# So we don't touch it here.
					$has_response = 1;
				}
			} elsif (defined $file && -d $file) {
				# It's a directory. Do we show the listing?
				if ($self->{config}->{show_indexes}) {
					$response_body = $self->show_index($file);
					$content_type  = "text/html" if $response_body;
					$has_response  = 1 if $response_body;
				} else {
					$status = RC_FORBIDDEN;
				}
			}

			# Do we have an adequate response?
			if ($has_response) {
				# Make an HTTP response for them.
				my $resp = HTTP::Response->new($status);
				$resp->header("Content-Type" => $content_type);
				$resp->content($response_body);
				$c->send_response($resp);
			} else {
				$c->send_error($status);
			}

			# Print it for the access log.
			print "$address: $method $path" . ($query ? "?$query" : "") . " $status\n";
		}

		$c->close;
		undef($c);
	}

	return 1;
}

=head2 string resolve_path (string uri)

Convert a URI request path to a file on disk. Returns undef to indicate that no
such file exists on disk.

=cut

sub resolve_path {
	my ($self, $uri) = @_;

	# Normalize the URI.
	$uri =~ s{^/+}{}g; # Remove preceding slashes.
	$uri =~ s{/+$}{}g; # Remove trailing slashes.
	$uri =  uri_unescape($uri);

	# We don't play games with "/../"
	$uri =~ s{\.+}/./g;
	$uri =~ s{/+}{/}g; # Remove duplicate slashes

	# Look for a file on disk.
	my $path = "$self->{config}->{document_root}" . ($uri ? "/$uri" : "");
	if (-d $path) {
		# It's a directory. Look for index files.
		foreach my $index (@{$self->{config}->{directory_index}}) {
			if (-f "$path/$index") {
				# Found one!
				return ("$path/$index", $uri);
			}
		}

		# Just return the directory.
		return ($path, $uri);
	} elsif (-f $path) {
		# It's a file.
		return ($path, $uri);
	} else {
		# Nothing was found here.
		return (undef, $uri);
	}
}

=head2 string show_index (string path)

Retrieve a directory index for C<path>. This will use the template file at
C<document_root/errors/index.html>, or a really barebones default template if
that file doesn't exist.

=cut

sub show_index {
	my ($self, $path) = @_;

	my $root = $path;
	$root =~ s/^\Q$self->{config}->{document_root}\E//;

	my $cwd = $root;
	$cwd =~ s/\/$//g; # Remove trailing slashes.

	# Get the directory list.
	my $vars = {
		root    => $root,
		cwd     => $cwd,
		folders => [],
		files   => [],
	};
	opendir (my $dir, $path);
	foreach my $file (sort(grep(!/^\./, readdir($dir)))) {
		if (-d "$path/$file") {
			push @{$vars->{folders}}, $file;
		} else {
			push @{$vars->{files}}, $file;
		}
	}
	closedir ($dir);

	# A template exists?
	my $template;
	if (-f "$self->{config}->{document_root}/errors/index.html") {
		$template = "$self->{config}->{document_root}/errors/index.html";
	} else {
		# Make the generic barebones one.
		$template = qq{<!DOCTYPE html>
<html>
<head>
<title>Index of [% root %]</title>
</head>
<body>

<h1>Index of [% root %]</h1>

<ul>
	[% IF root != "/" %]
		<li><a href="../">Up one level</a></li>
	[% END %]
	[% FOREACH item = folders %]
		<li><a href="[% cwd %]/[% item %]">[% item %]/</a></li>
	[% END %]
	[% FOREACH item = files %]
		<li><a href="[% cwd %]/[% item %]">[% item %]</a></li>
	[% END %]
</ul>

</body>
</html>};
	}

	return $self->render_template($template, $vars);
}

=head2 text render_template (string template, hashref vars)

Simple wrapper around Template Toolkit. C<template> can either be a file that
exists on the hard drive, or the string body of a template. C<vars> is the hash
of variables for the template.

=cut

sub render_template {
	my ($self, $template, $vars) = @_;

	my $tt = Template->new(
		RELATIVE => 1,
		ABSOLUTE => 1,
	);

	my $output;
	$tt->process(
		(-f $template) ? $template : \$template,
		$vars,
		\$output,
	);

	return $output;
}

=head2 string make_sandbox ()

Generate a random 16-letter string. This is used when the HTTP daemon needs to
execute a Perl CGI script directly (because there was no external Perl
interpreter available).

CGI scripts run in this way are placed into the package
C<RiveScript::HTTPd::Sandbox::$sandbox>, to keep them (relatively) isolated from
the C<main> package or C<RiveScript::HTTPd>.

=cut

sub make_sandbox {
	my ($self) = @_;

	my @chars = qw(
		A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
		a b c d e f g h i j k l m n o p q r s t u v w x y z
	);

	my $sandbox = "";
	for (my $i = 0; $i < 16; $i++) {
		$sandbox .= $chars[ int(rand(scalar(@chars))) ];
	}

	return $sandbox;
}

=head1 OPTIONS

Here is the list of all the supported options and their default values.

Note that B<boolean> values require a value of either C<0> or C<undef> to
indicate that they are false. Any value that is "truthy" to Perl indicates
true - usually the number C<1>.

=over 4

=item document_root: STRING

The directory to serve documents from. The default is C<./public_html> in
the current working directory.

=item directory_index: @STRING

The list of files to serve as the directory index. The default values are:

  index.cgi, index.pl, index.html, index.htm

The files will be checked for in that order. If one is found, it will be
served to the user. If none are found, a directory listing may be sent
depending on the C<show_indexes> option.

=item show_indexes: BOOLEAN

Whether or not a directory index will be given to the user if they navigate
to a directory that doesn't include an index page. The default value is
C<1>, or "true".

If false, the user is sent a 403 Forbidden error page instead.

=item cgi_scripts: @STRING

The list of file extensions that should be considered to be CGI scripts.
See L<"CGI SCRIPTS"> for information on how these scripts will be handled.
The default values are:

  .cgi, .pl

Setting this option to an empty array will effectively disable CGI script
execution completely.

=back

=head2 MIME Types

To define MIME types for certain file extensions, use the extension as the
option, including the period. For example "C<.html>".

  $daemon->set_option(".html" => "text/html");

By default, MIME types are defined for the following file types. These may
be overridden if you desire.

  .html, .htm              text/html
  .text, .txt, .asc        text/plain
  .css                     text/css
  .js                      text/javascript
  .dtd                     text/xml
  .xml                     text/xml
  .gif                     image/gif
  .png                     image/png
  .jpg, .jpeg, .jpe        image/jpeg
  .xbm                     image/x-xbitmap
  .xpm                     image/x-xpixmap
  .ico                     image/x-icon
  .mp3                     audio/mpeg
  .m3u                     audio/x-mpegurl
  .wma                     audio/x-ms-wma
  .wax                     audio/x-ms-wax
  .ogg                     application/ogg
  .wav                     audio/x-wav
  .mpeg, .mpg              video/mpeg
  .avi                     video/x-msvideo
  .asf, .asx               video/x-ms-asf
  .wmv                     video/x-ms-wmv
  .zip                     application/zip
  .pdf                     application/pdf
  .gz                      application/x-gzip
  .tar.gz, .tgz            application/x-tgz
  .tar                     application/x-tar
  .bz2                     application/x-bzip
  .tar.bz2, .tbz           application/x-bzip-compressed-tar

=head1 CGI SCRIPTS

This daemon supports the execution of CGI scripts within the document root.

To enable CGI scripts, make sure that the C<cgi_scripts> option is defined and
is set to an array of file extensions that are considered to be CGI scripts.
To I<disable> CGI scripts, set this option to an empty array reference.

When a CGI script is requested, the first line of the script (the shebang line)
is read so that an interpreter can be located to run the script with. If the
interpreter was found, it will be called to execute the script and will be
given a standard set of CGI environment variables (see the caveats, below).

If no interpreter could be found, but the shebang line includes C<perl>, the
daemon will attempt to execute the Perl script by itself. This may fail (and
possibly crash the daemon) if the CGI script includes third-party modules that
the daemon itself hasn't loaded. This should be okay for the RiveScript CGI
scripts included with the daemon, but beware when running custom CGI scripts,
especially if you're using a pre-compiled (C<.exe>) distribution of the daemon.

=head2 Caveats

File uploading support for CGI scripts probably doesn't work. C<POST> requests
probably won't work either. The CGI scripts should only rely on the
C<QUERY_STRING>, C<COOKIE> and C<REMOTE_ADDR> parameters for the most part.

=cut

1;
