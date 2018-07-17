#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListSourceProjectSequence(){
	local PKG="$1"
	if [ -z "$PKG" ] ; then
		echo "ListSourceProjectSequence: 'PKG' argument is required!" >&2 ; return 1
	fi
	
	"$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" --import-from-source --select-project $PKG --print-sequence --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectSequence.fn.sh) 

		# . "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		# DistroShellContext --distro-from-source
		
		ListSourceProjectSequence "$@"
	;;
esac