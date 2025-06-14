#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

CleanCachedToOutput(){

	echo "CleanCachedToOutput: 🧻 Cleaning Output directory" >&2
	rm -rf "$MMDAPP/output"
	
	if type DistroShellContext >/dev/null 2>&1 ; then
		echo "CleanCachedToOutput: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroShellContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanCachedToOutput.fn.sh) 
		# "$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""
		CleanCachedToOutput "$@"
	;;
esac
