#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

CleanCachedToOutput(){
	case "$1" in
		--help|--help-syntax)
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.CleanCachedToOutput.include"
			return 0
		;;
	esac

	echo "CleanCachedToOutput: 🧻 Cleaning Output directory" >&2
	rm -rf "$MMDAPP/output" "$MMDAPP/.local/output-cache"
	
	if type DistroSystemContext >/dev/null 2>&1 ; then
		echo "CleanCachedToOutput: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroSystemContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanCachedToOutput.fn.sh) 
		# "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""
		CleanCachedToOutput "$@"
	;;
esac
