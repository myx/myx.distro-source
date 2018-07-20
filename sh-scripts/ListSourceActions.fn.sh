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


ListSourceActions(){
	Require ListAllProjects
	Require ListSourceProjectActions
		
	for PKG in $( ListAllProjects ) ; do
		ListSourceProjectActions "$PKG"
	done	
}

case "$0" in
	*/sh-scripts/ListSourceActions.fn.sh) 
		ListSourceActions
	;;
esac