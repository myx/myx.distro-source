#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi


ListSourceProjectSequence(){
	local PKG="$1"
	if [ -z "$PKG" ] ; then
		echo "ERROR: ListSourceProjectSequence: 'PKG' argument is required!" >&2 ; return 1
	fi
	
	Require DistroSourceCommand
	DistroSourceCommand \
		--import-from-source \
		--select-project $PKG \
		--print-sequence --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectSequence.fn.sh) 
		ListSourceProjectSequence "$@"
	;;
esac