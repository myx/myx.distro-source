#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
fi

Require BuildCachedFromSource
Require BuildOutputFromCached
Require ListDistroBuilders

RebuildDistroFromOutputBuilderRaw(){
	set -e
	
	local BUILDER="$1"
	echo "BuildDistroFromSource: $( basename $BUILDER ) builder started" >&2
	#### want to run in separate process anyways
	if ( . "$MMDAPP/source/$BUILDER" | cat -u ) ; then
		echo "BuildDistroFromSource: $( basename $BUILDER ) builder done." >&2
	else
		echo "⛔ ERROR: BuildDistroFromSource: $( basename $BUILDER ) failed!" >&2
		set +e ; return 1
	fi
}

BuildDistroFromOutputRunner(){
	set -e
	
	export OUTPUT_PATH="$MMDAPP/output/distro"
	export DISTRO_PATH="$MMDAPP/output/distro"
	export EXPORT_PATH="$MMDAPP/output/export"
	
	export BUILD_STAMP="$( date -u "+%Y%m%d%H%M%S" )"
	
	type Prefix >/dev/null 2>&1 || \
		. "`myx.common which lib/prefix`"
	
	type Async >/dev/null 2>&1 || \
		. "`myx.common which lib/async`"
	
	DistroSystemContext --distro-from-output
	
	local BUILDERS="$( ListDistroBuilders image-prepare --3 )"
	echo "BuildDistroFromSource: Builders list:" $BUILDERS >&2
	
	for BUILDER in $BUILDERS ; do
		Prefix "s $( basename $BUILDER )" RebuildDistroFromOutputBuilderRaw "$BUILDER"
		wait
	done

	echo "BuildDistroFromSource: All Builders passed." >&2
}

BuildDistroFromSource(){
	set -e

	BuildCachedFromSource "$@"
	BuildOutputFromCached "$@"
	
	#### want to run in separate process anyways
	BuildDistroFromOutputRunner "$@" | cat -u
}

case "$0" in
	*/sh-scripts/BuildDistroFromSource.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-source
		
		BuildDistroFromSource "$@"
	;;
esac
