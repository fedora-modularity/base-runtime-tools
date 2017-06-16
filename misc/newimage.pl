#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use Sys::Hostname;

open my $fh, '<', dirname(__FILE__) . '/.credentials.docker'
    or die "Cannot read docker credentials!\n";
$_ = <$fh>; chomp;
my ($dockeruser, $dockerpassword) = split ':';
close $fh;

my $dockerdir = '/home/build/tests/baseruntime-docker-tests';
chdir $dockerdir or die "Cannot change directory!\n";

my $sender = 'The Base Runtime Team <rhel-next@redhat.com>';
# Default to the team if no recipient is specified
my $recipients = shift @ARGV // join(', ',
    'mmcgrath@redhat.com',
    'contyk@redhat.com',
    'ignatenko@redhat.com',
    'sgallagher@redhat.com',
    'merlinm@redhat.com',
    'bgoncalv@redhat.com',
);
my $hostname = hostname();
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

---

You can find logs online here: http://${hostname}/job-results/

EOF


my $module_lint = "/usr/share/moduleframework/tools/modulelint.py";
my @steps = (
  # [ test_success, save_output, command, fail_message, ],
  [ 0, 0, "git pull -q", "Git pull failed", ],
  [ 1, 1, "avocado run ./setup.py 2>&1", "Failed to build image", ],
  [ 1, 1, "avocado run ./smoke.py ${module_lint} 2>&1", "Tests failed", ],
  [ 1, 0, "docker login --username ${dockeruser} --password ${dockerpassword}", "Docker Hub login failed", ],
  [ 1, 0, "docker tag base-runtime-smoke baseruntime/baseruntime", "Image tagging failed", ],
  [ 1, 0, "docker push baseruntime/baseruntime", "Pushing to Docker Hub failed", ],
  [ 0, 0, "docker rmi baseruntime/baseruntime", "Image cleanup failed", ],
  [ 1, 1, "avocado run ./teardown.py 2>&1", "Cleanup failed", ],
);

my $result = 'OK!';
my $output = '';

foreach my $step (@steps) {
  my ($test_success, $save_output, $command, $fail_message) = @$step;

  my $out = qx/$command/;

  $output .= $out . "\n" if $save_output;

  if ($test_success && ($? >> 8) != 0) {
    $result = $fail_message;
    last;
  }
}

$mail =~ s/__RESULT__/$result/;
$mail =~ s/__OUTPUT__/$output/;

my $status = $result eq 'OK!' ? 'OK' : 'FAILED';

$mail =~ s/__STATUS__/$status/;

open my $pipe, '|/usr/sbin/sendmail -t';
print { $pipe } $mail;
close $pipe;
