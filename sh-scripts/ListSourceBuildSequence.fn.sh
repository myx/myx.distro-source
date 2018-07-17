#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListSourceBuildSequence(){
	"$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" "$@" --import-from-source --select-all --print-sequence --print ""
}

case "$0" in
	*/sh-scripts/ListSourceBuildSequence.fn.sh) 
		ListSourceBuildSequence "$@"
	;;
esac