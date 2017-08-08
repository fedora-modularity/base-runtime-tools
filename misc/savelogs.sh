#!/bin/sh
build=$1
[ -z "$build" ] && { echo "Usage: savelogs.sh <build>"; exit; }
[ -d ~/results/$build ] || { echo "Build $build doesn't exist!"; exit; }
[ -d ~/logs/$build ] && { echo "Logs for $build already exist!"; exit; }
mkdir ~/logs/$build
cd ~/results/$build/results
cp -R repodata ~/logs/$build/
for pkg in $(grep -Fl failed *-status.log|sed 's/-status\.log//'); do
	for log in build mock-stderr mock-stdout root state status; do
		[ -f $pkg-$log.log ] && ln $pkg-$log.log ~/logs/$build/
	done
done
