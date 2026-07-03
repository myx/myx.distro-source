#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

CleanSourceToCached(){
	case "$1" in
		--help|--help-syntax)
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.CleanSourceToCached.include"
			return 0
		;;
	esac

	echo "CleanSourceToCached: 🧻 Cleaning Output directory" >&2
	rm -rf "$MMDAPP/cached" # << old location
	rm -rf "$MMDAPP/.local/source-cache"
	
	if type DistroSystemContext >/dev/null 2>&1 ; then
		echo "CleanSourceToCached: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroSystemContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanSourceToCached.fn.sh) 
		CleanSourceToCached "$@"
	;;
esac
