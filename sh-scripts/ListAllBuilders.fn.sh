#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

Require ListDistroProjects
Require ListProjectBuilders

ListAllBuildersRaw(){
	local stageType="$1"
	if [ -z "$1" ] ; then
		echo "ListAllBuildersRaw: 'stageType' argument is required!" >&2 ; return 1
	fi
	local projectName
	for projectName in ` ListDistroProjects --all-projects ` ; do
		ListProjectBuilders "$projectName" "$@"
	done
}

ListAllBuilders(){
	ListAllBuildersRaw "$@" |\
				    awk -v FS=/ -v OFS=/ '{ print $NF,$0 }' |\
				    sort -n -t / |\
				    cut -f2- -d/
}

case "$0" in
	*/sh-scripts/ListAllBuilders.fn.sh) 
		
		ListAllBuilders "$@"
	;;
esac