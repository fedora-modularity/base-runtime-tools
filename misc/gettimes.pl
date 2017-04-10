#!/usr/bin/perl
use strict;
use warnings;
use YAML::XS qw/LoadFile/;

my $results = shift @ARGV or die "Usage: gatherdata.pl <logsdir>\n";

my $d = LoadFile($ENV{HOME} . '/modules/bootstrap/bootstrap.yaml');
my @c = keys %{$d->{data}->{components}->{rpms}};

chdir $results;

for my $p (sort @c) {
        my $t;
	if (-f "$p-status.log" ) {
		$t = (stat("$p-status.log"))[9] - (stat("$p-mock-stdout.log"))[9];
	} else {
		$t = '-';
	}
        print "$p: $t\n";
}
