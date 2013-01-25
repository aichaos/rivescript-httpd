#!/usr/bin/perl

use 5.16.0;
use strict;
use warnings;
use CGI;

my $q = CGI->new();

my $name = $q->param("name");
my $id = `id`;

print $q->header();
print qq{<h1>Test Script!</h1>

The query "name" is: [$name]<p>

The output of `id`: $id};
