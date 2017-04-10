#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

open my $fh, '<', basename(__FILE__) . '/.credentials.docker'
    or die "Cannot read docker credentials!\n";
<>; chomp;
my ($dockeruser, $dockerpassword) = split ':', $_;
close $fh;

chdir '/home/build/tests/baseruntime-docker-tests'
    or die "Cannot change directory!\n";

my $output;
my $sender = 'The Base Runtime Team <contyk@redhat.com>';
# Default to self if no recipient is specified
my $recipients = shift @ARGV // 'contyk@redhat.com';
my $mail = <<"EOF";
Subject: [Base Runtime] Boltron Docker base image report
From: ${sender}
To: ${recipients}
X-base-runtime-image-status: __STATUS__

Heyhowareya!

This is your automated Boltron Docker base image report!
The output from the latest update run can be found below.

Status: __RESULT__

If all went well, your updated image is now available at docker.io.
Get it with and lists the installed packages with:

    \$ docker pull baseruntime/baseruntime
    \$ docker run --rm docker.io/baseruntime/baseruntime rpm -qa

---

__OUTPUT__

EOF

my $result = 'Unknown';

# TODO: Guess this should be tested
qx/git pull -q/;

$output = qx/avocado run .\/setup.py 2>&1/;
if (($? >> 8) != 0) {
    $result = 'Failed to build image';
} else {
    $output .= "\n" . qx/avocado run .\/smoke.py 2>&1/;
    if (($? >> 8) != 0) {
        $result = 'Tests failed';
    } else {
        qx/docker login --username ${dockeruser} --password ${dockerpassword}/;
        if (($? >> 8) != 0) {
            $result = 'Docker Hub login failed';
        } else {
            qx/docker tag base-runtime-smoke baseruntime\/baseruntime/;
            if (($? >> 8) != 0) {
                $result = 'Image tagging failed';
            } else {
                qx/docker push baseruntime\/baseruntime/;
                if (($? >> 8) != 0) {
                    $result = 'Pushing to Docker Hub failed';
                } else {
                    qx/docker rmi baseruntime\/baseruntime/;
                    $output .= "\n" . qx/avocado run .\/teardown.py 2>&1/;
                    if (($? >> 8) != 0) {
                        $result = 'Cleanup failed';
                    } else {
                        $result = 'OK!';
                    }
                }
            }
        }
    }
}

$mail =~ s/__RESULT__/$result/;
$mail =~ s/__OUTPUT__/$output/;

my $status = $result eq 'OK!' ? 'OK' : 'FAILED';

$mail =~ s/__STATUS__/$status/;

open my $pipe, '|/usr/sbin/sendmail -t';
print { $pipe } $mail;
close $pipe;
