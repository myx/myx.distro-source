#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP" >&2
	[ -d "$MMDAPP/.local" ] || ( echo "⛔ ERROR: expecting '.local' directory." >&2 && exit 1 )
fi

CleanAllOutputs(){
	case "$1" in
		--help|--help-syntax)
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.CleanAllOutputs.include"
			return 0
		;;
	esac

	echo "CleanAllOutputs: 🧻 Cleaning Output directories" >&2
	rm -rf \
		"$MMDAPP"/{output,cached,export,distro} \
		"$MMDAPP/.local"/{source-cache,output-cache,system-index} \
		"$MMDAPP/.local/temp/javac"
	
	if type DistroSystemContext >/dev/null 2>&1 ; then
		echo "CleanAllOutputs: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroSystemContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanAllOutputs.fn.sh) 
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		CleanAllOutputs "$@"
	;;
esac
