#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListAllActions(){

	Require ListDistroProjects
	Require ListProjectActions
	
	for projectName in ` ListDistroProjects --all-projects ` ; do
		ListProjectActions "$@" "$projectName"
	done
		
}

case "$0" in
	*/sh-scripts/ListAllActions.fn.sh) 
		ListAllActions "$@"
	;;
esac