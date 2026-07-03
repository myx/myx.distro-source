#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


Help(){
	. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.Help.include"
}

case "$0" in
	*/sh-scripts/Help.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"

		Help "$@"
	;;
esac
