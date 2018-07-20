#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListAllActions(){

	Require ListAllProjects
	Require ListProjectActions
	
	for PKG in $( ListAllProjects ) ; do
		ListProjectActions "$@" "$PKG"
	done
		
}

case "$0" in
	*/sh-scripts/ListAllActions.fn.sh) 
		ListAllActions "$@"
	;;
esac