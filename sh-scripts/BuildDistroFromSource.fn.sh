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

Require BuildCachedFromSource
Require BuildOutputFromCached

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
	
	for BUILDER in $( ListAllBuilders image-prepare --3 ) ; do
		Prefix "o $( basename $BUILDER )" RebuildOutputFromCachedBuilderRaw "$BUILDER"
		wait
	done
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