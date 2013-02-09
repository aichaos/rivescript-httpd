#!/usr/bin/perl

use strict;
use warnings;

# Get the file list.
my @files;
opendir(my $dh, "public_html/brain");
foreach my $file (sort(grep { /\.rs$/i } readdir($dh))) {
	push @files, $file;
}
closedir($dh);

# Format them for the JS.
my $filelist = join(",\n", map { "\t'$_'" } @files);

# Generate the JS.
my $js = qq{/* This file was automatically generated. You shouldn't
 * need to edit this file by hand. If you need to add files
 * to this list, instead run the "Refresh the File List"
 * command in the RiveScript::HTTPd index page. */

var rs_filelist = [
$filelist
];
};

open (my $fh, ">", "public_html/js/brain.js") or die "Can't do it";
print {$fh} $js;
close ($fh);

print "Content-Type: text/html\n\n";
print qq{<!DOCTYPE html>
<html>
<head>
<title>Refresh the File List</title>
<link rel="stylesheet" type="text/css" href="/css/rs-httpd.css">
</head>
<body>

<div id="header">Refresh the File List</div>

<div id="content">
	<h1>File list refreshed!</h1>

	The file <code>public_html/js/brain.js</code> has been regenerated based
	on the files in the <code>public_html/brain</code> directory.<p>

	<a href="/">Return to the main page</a>
</div>

</body>
</html>};
