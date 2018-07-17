#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


ShowDistroInfo(){
	echo "Syntax: Distro <commandName> ...<arguments>" >&2
	echo "	Info:" >&2
	echo "		distro folder: $MMDAPP" >&2
	echo "		MDSC_OPTION: ${MDSC_OPTION:-"Not Set"}" >&2
	echo "		MDSC_SOURCE: ${MDSC_SOURCE:-"Not Set"}" >&2
	echo "		MDSC_CACHED: ${MDSC_CACHED:-"Not Set"}" >&2
	echo "		MDSC_OUTPUT: ${MDSC_OUTPUT:-"Not Set"}" >&2
}

case "$0" in
	*/sh-scripts/ShowDistroInfo.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		ShowDistroInfo "$@"
	;;
esac