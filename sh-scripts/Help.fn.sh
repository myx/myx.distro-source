#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


Help(){
	echo "Syntax: Distro <commandName> ...<arguments>" >&2
	echo "	Start with:" >&2
	echo "		Distro ShowDistroInfo.fn.sh" >&2
}

case "$0" in
	*/sh-scripts/Help.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		
		Help "$@"
	;;
esac