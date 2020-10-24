#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
fi

Require ListAllBuilders
Require BuildCachedFromSource
Require BuildOutputFromCached

RebuildDistroFromOutputBuilderRaw(){
	set -e
	
	local BUILDER="$1"
	echo "BuildDistroFromSource: $( basename $BUILDER ) builder started" >&2
	#### want to run in separate process anyways
	if ( . "$MMDAPP/source/$BUILDER" | cat -u ) ; then
		echo "BuildDistroFromSource: $( basename $BUILDER ) builder done." >&2
	else
		echo "BuildDistroFromSource: ERROR: $( basename $BUILDER ) failed!" >&2
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
	
	DistroShellContext --distro-from-output
	
	local BUILDERS="$( ListAllBuilders image-prepare --3 )"
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
		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-from-source
		
		BuildDistroFromSource "$@"
	;;
esac