#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw/fileparse/;
use File::Find::Rule;
use YAML::XS qw/LoadFile/;

die "Usage: ./compose.pl <results dirs>\n" unless @ARGV;
die "Compose already exists; aborting.\n" if -d $ENV{HOME} . '/compose';

mkdir $ENV{HOME} . '/compose' or die "Cannot create the compose directory: $!\n";

my $d = LoadFile($ENV{HOME} . '/modules/base-runtime/base-runtime.yaml');
my @api = @{$d->{data}->{api}->{rpms}};

my %rpms;
for my $rpm (File::Find::Rule->file()->name('*.rpm')->in(@ARGV)) {
        next unless $rpm =~ /(x86_64|noarch)\.rpm$/;
        $rpm =~ /^.*\/(.+?)-[^-]+-[^-]+\.rpm$/;
        $rpms{$1} = $rpm;
}

for my $pkg (@api) {
        unless (exists $rpms{$pkg}) {
                print "Missing RPM for ${pkg}!\n";
                next
        }
        link $rpms{$pkg}, $ENV{HOME} . '/compose/' . fileparse($rpms{$pkg}) or die "Cannot create link for ${pkg}: $!\n";
}

system 'createrepo_c', '--workers', 100, $ENV{HOME} . '/compose';
system 'modifyrepo_c', '--mdtype=modules', $ENV{HOME} . '/modules/base-runtime/base-runtime.yaml', $ENV{HOME} . '/compose/repodata';
