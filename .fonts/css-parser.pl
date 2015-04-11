#!/usr/bin/perl

use strict;
use warnings;

my $face = undef;
my $style = undef;
my $weight = undef;

while (<>) {
	s/^\s*|\s*;\s*$//g;
	$face = $1 if /font-family:\s*'([^']+)'/;
	$style = $1 if /font-style:\s*(.+)/;
	$weight = $1 if /font-weight:\s*(.+)/;
	next unless /src:.*?url\(([^)]+?\.ttf)\)/;
	my $url = $1;
	print STDERR " * $style @ $weight\n";
	$face =~ s/\s/_/g;
	print "$face-$style-$weight\n$url\n";
}
