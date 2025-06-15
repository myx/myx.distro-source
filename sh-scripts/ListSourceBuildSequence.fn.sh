#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


if [ -z "$MDLT_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	# DistroShellContext --distro-from-source
fi


ListSourceBuildSequence(){
	Require DistroSourceCommand
	DistroSourceCommand "$@" --import-from-source --select-all --print-sequence --print ""
	# "$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" "$@" --import-from-source --select-all --print-sequence --print ""
}

case "$0" in
	*/sh-scripts/ListSourceBuildSequence.fn.sh) 
		ListSourceBuildSequence "$@"
	;;
esac
