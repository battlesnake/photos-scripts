#!/usr/bin/perl

# Renames photo albums using new indexes (new=old+20)

die "Already done";

use strict;

use warnings;

my @list = reverse(glob('*'));

while (my $filename = shift @list) {
	$_ = $filename;
	next unless /^0*(\d*)\s(.*)$/;
	my $idx = $1;
	my $name = $2;
	next if ($idx eq "") || ($idx == 0);

	my $newname = sprintf('%03d %s', $idx + 20, $name);

	rename($filename, $newname);
	printf('"%s" => "%s"%s', $filename, $newname, "\n");
}
