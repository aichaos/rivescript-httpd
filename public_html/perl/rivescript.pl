#!/usr/bin/perl

# RiveScript::HTTPd Example Perl CGI Bot
#
# Invoke this script using an Ajax call. It uses JSON encoding for its input and
# output. See public_html/perl/bot.js for usage example.
#
# NOTE: This CGI script would run on an Apache server using mod_cgi. This means
# that for each and every request, your entire RiveScript brain will need to be
# loaded from scratch. This should be okay for small-to-medium size bots,
# especially when the bots won't be chatted with simultaneously by a significant
# number of users. If you see any performance problems, consider switching to the
# FastCGI version instead.

use 5.14.0;
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use RiveScript;
use Digest::MD5 qw(md5_hex);
use JSON;
use DBI;

my $q = CGI->new();
my $cookie; # Outgoing HTTP cookie

# Load the config file.
my $conf = {};
foreach my $try (qw(config.pl public_html/perl/config.pl)) {
	if (-f $try) {
		$conf = do $try;
	}
}

# We speak JSON.
my $json = JSON->new->utf8->pretty;
my $resp = {
	status => 'error',
};

# Cancel early on obvious errors.
if (scalar keys %{$conf} == 0) {
	$resp->{error} = "Couldn't locate config.pl to load bot settings.";
}
elsif (!-d $conf->{brain_path}) {
	$resp->{error} = "Can't find brain path ($conf->{brain_path}): no directory found at that path!";
}

# Need to connect to a SQL database?
my $dbh;
if ($conf->{session_method} eq 'mysql') {
	# Connect to MySQL.
	$dbh = DBI->connect("dbi:mysql:$conf->{mysql_database}", $conf->{mysql_user}, $conf->{mysql_password});
	unless ($dbh) {
		$resp->{error} = "Couldn't connect to MySQL server: $DBI::errstr";
	}
} else {
	# JSON.
	if (!-d $conf->{json_root}) {
		$resp->{error} = "JSON session root ($conf->{json_root}) not found!";
	}
}

# Get or generate their unique session ID.
expire_sessions(); # Clean up old sessions first.
my $sessid = session_id();
$cookie = $q->cookie(
	-name    => $conf->{session_cookie},
	-value   => $sessid,
	-expires => '+365d',
);

# Handle their request.
unless ($resp->{error}) {
	my $msg = $q->param('message');

	if (defined $msg) {
		# Initialize RiveScript.
		my $rs = RiveScript->new();
		$rs->loadDirectory($conf->{brain_path});
		$rs->sortReplies();

		# Recall their session.
		recall_session($rs);

		# Get a reply for them.
		my $reply = $rs->reply($sessid, $msg);

		# Save changes to their session.
		write_session($rs);

		$resp->{status} = 'ok';
		$resp->{name}   = $conf->{bot_name};
		$resp->{reply}  = $reply;
	} elsif ($q->param('welcome')) {
		$resp->{status} = 'ok';
		$resp->{name}   = $conf->{bot_name};
		$resp->{reply}  = $conf->{welcome};
	} else {
		$resp->{error} = 'No message provided by the user.';
	}
}

print $q->header(
	-type   => 'application/json',
	-cookie => $cookie,
);
$resp->{session} = $sessid;
print $json->encode($resp);

################################################################################
# Utility Methods                                                              #
################################################################################

# Load the user's variables from their session.
sub recall_session {
	my $rs = shift;

	if ($conf->{session_method} eq 'mysql') {
		my $sth = $dbh->prepare(q{
			SELECT vars
			FROM rs_session
			WHERE sessid=?
		});
		$sth->execute($sessid);

		while (my $row = $sth->fetchrow_hashref) {
			my $vars = $json->decode($row->{vars});
			$resp->{mysql_2} = $vars;
			foreach my $var (keys %{$vars}) {
				$rs->setUservar($sessid, $var, $vars->{$var});
			}
		}
	} else {
		return unless -f "$conf->{json_root}/$sessid.json"; # No session yet

		local $/;
		open (my $fh, "<", "$conf->{json_root}/$sessid.json");
		my $data = <$fh>;
		close ($fh);

		my $vars = $json->decode($data);
		foreach my $var (keys %{$vars}) {
			$rs->setUservar($sessid, $var, $vars->{$var});
		}
	}
}

# Write changes to their session.
sub write_session {
	my $rs = shift;

	my $vars = $rs->getUservars($sessid);

	if ($conf->{session_method} eq 'mysql') {
		my $sth = $dbh->prepare(q{
			REPLACE INTO rs_session
			SET sessid=?, vars=?, last_modified=NOW()
		});
		$sth->execute($sessid, $json->encode($vars));
		$resp->{mysql} = $sth->errstr;
	} else {
		open (my $fh, ">", "$conf->{json_root}/$sessid.json");
		print {$fh} $json->encode($vars);
		close ($fh);
	}
}

# Generate or get their unique session ID.
sub session_id {
	# See if they have one in a cookie.
	my $sessid = $q->cookie(-name => $conf->{session_cookie});
	$sessid =~ s/[^A-Za-z0-9]//g;
	if ($sessid && length $sessid == 32) {
		return $sessid;
	}

	# Need to generate a new one.
	$sessid = generate_sessid();

	# Make sure it's still available.
	if ($conf->{session_method} eq 'mysql') {
		while (1) {
			my $sth = $dbh->prepare("select sessid from rs_session where sessid = ?");
			$sth->execute($sessid);
			if (my $row = $sth->fetchrow_hashref) {
				$sessid = generate_sessid();
				next; # Try, try again!
			}
			last; # Got one!
		}
	} else {
		while (-f "$conf->{json_root}/$sessid.json") {
			$sessid = generate_sessid();
		}
	}

	return $sessid;
}

# Generate a random session ID string.
sub generate_sessid {
	return md5_hex(int(rand(999_999)));
}

# Expire old session IDs.
sub expire_sessions {
	if ($conf->{session_method} eq 'mysql') {
		my $sth = $dbh->prepare(qq{
			DELETE FROM rs_session
			WHERE last_modified < DATE_SUB(NOW(), INTERVAL $conf->{session_expire_mysql})
		});
		$sth->execute();
	} else {
		# Delete old JSON files.
		opendir(my $dh, $conf->{json_root});
		foreach my $file (sort(grep(/\.json$/i, readdir($dh)))) {
			my ($mtime) = (stat("$conf->{json_root}/$file"))[9];
			if (time() - $mtime > $conf->{session_expire_seconds}) {
				unlink("$conf->{json_root}/$file");
			}
		}
		closedir($dh);
	}
}
