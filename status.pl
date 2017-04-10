#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';
use autodie;
use File::Find::Rule;
use Getopt::Std;

chdir $ENV{HOME} . '/results/';

sub HELP_MESSAGE {
    print "Usage: watch.pl -m MODULE [-s STREAM] [-v VERSION]\n\n";
    print "MODULE is the module name to monitor, required\n";
    print "STREAM is the module stream name, defaults to master\n";
    print "VERSION is the module version, defaults to the latest found\n";
    exit 1;
}

my %opts; getopts('m:s:v:', \%opts);

HELP_MESSAGE unless $opts{m};
$opts{s} = $opts{s} // 'master';
$opts{v} = $opts{v} // (sort(glob("module-$opts{m}-$opts{s}-*")))[-1] =~ s/^.*-//r;

my $dir = "module-$opts{m}-$opts{s}-$opts{v}";

if (! -d $dir) {
    print "Cannot find any matching modules, sorry!\n";
    exit 2;
}

print "$dir\n" . '=' x length($dir) . "\n\n";

chdir "${dir}/results";

# %done contains states which point to ArrayRefs
my %done;
# %building contains package names that point to HashRefs
# with additional info, such as when the build started
my %building;

for my $file (glob('*-status.log')) {
    open my $fh, '<', $file;
    my $status = <$fh>; chomp $status;
    my $pkg = $file =~ s/-status\.log$//r;
    $done{$status} = [] if ! exists $done{$status};
    push @{ $done{$status} }, $pkg;
    close $fh;
}

for my $file (File::Find::Rule->file()->name('state.log')->in('.')) {
    open my $fh, '<', $file;
    {
        local $/ = undef; my $status = <$fh>;
        if ($status =~ /^([^,]+?),.*?Start: build phase for (.*?)-[^-]+-[^-]+\.src\.rpm$/sm) {
            $building{$2}->{started} = $1;
        }
    }
    close $fh;
}

print 'Building: ' . scalar(keys %building) . "\n";
for my $state (sort keys %done) {
    print ucfirst($state) . ': ' . scalar(@{ $done{$state} }) . "\n";
}
print "\n";

if (%building) {
    print "Currently building:\n\n";
    for my $pkg (sort keys %building) {
        print '  * ' . $pkg . ' (started: ' . $building{$pkg}->{started} . ")\n";
    }
    print "\n";
}

if (exists $done{failed}) {
    print "Failed to build:\n\n  * ";
    print join("\n  * ", sort @{ $done{failed} });
    print "\n";
}
