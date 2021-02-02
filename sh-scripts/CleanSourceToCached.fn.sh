#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

CleanSourceToCached(){

	echo "CleanSourceToCached: 🧻 Cleaning Output directory" >&2
	rm -rf "$MMDAPP/cached"
	
	if type DistroShellContext >/dev/null 2>&1 ; then
		echo "CleanSourceToCached: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroShellContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanSourceToCached.fn.sh) 
		CleanSourceToCached "$@"
	;;
esac