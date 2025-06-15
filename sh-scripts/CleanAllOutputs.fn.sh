#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

CleanAllOutputs(){

	echo "CleanAllOutputs: 🧻 Cleaning Output directory" >&2
	rm -rf "$MMDAPP/output" "$MMDAPP/cached" "$MMDAPP/export" "$MMDAPP/distro"
	
	if type DistroSystemContext >/dev/null 2>&1 ; then
		echo "CleanAllOutputs: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroSystemContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanAllOutputs.fn.sh) 
		CleanAllOutputs "$@"
	;;
esac
