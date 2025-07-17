#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-from-source
fi

Require DistroSourcePrepare

SourcePrepareDistroSyncToCached(){
	local MDSC_CMD='SourcePrepareDistroSyncToCached'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	if [ "$MDSC_INMODE" = "source" ] ; then
		{
			DistroSourcePrepare --scan-source-projects
		} \
		| DistroSourcePrepare --sync-cached-from-source

		return 0
	fi

	# re-run itself with enforced 'source' mode
	( 
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.include" 
		DistroSystemContext --distro-from-source 
		Distro SourcePrepareDistroSyncToCached "$@"
	)
}


case "$0" in
	*/sh-scripts/SourcePrepareDistroSyncToCached.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-source

		SourcePrepareDistroSyncToCached "$@"
	;;
esac
