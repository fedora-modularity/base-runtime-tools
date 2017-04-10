#!/bin/sh
#tags='f26-modularity'
tags=$*
topdir=$(pwd)
for tag in $tags; do
	path="$tag/latest/x86_64"
	mkdir -p $path
	cd $path
	for build in $(koji list-tagged $tag | tail -n +3 | sed 's/ .*//'); do
		koji download-build --arch noarch --arch x86_64 $build
	done
	cd $topdir
	createrepo_c --workers 100 $path
done
