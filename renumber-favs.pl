#!/usr/bin/perl -n

# Generates re-indexed name of given favourite

die "Already done";

use strict;

use warnings;

chomp;

my $filename = $_;
/^0*(\d*)\s(.*)$/;
my $idx = $1;
my $name = $2;

printf('%03d %s%s', $idx + 20, $name, "\n");
