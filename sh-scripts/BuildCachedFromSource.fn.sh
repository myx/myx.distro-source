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

Require ListAllRepositories
Require ListAllProjects
Require ListAllBuilders


RebuildCachedFromSourceBuilderRaw(){
	set -e
	
	local BUILDER="$1"
	#### want to run in separate process anyways
	if ( . "$MMDAPP/source/$BUILDER" | cat -u ) ; then
		echo "done."
	else
		echo "ERROR: $BUILDER failed!" >&2
	fi
}

BuildCachedFromSourceRunner(){
	set -e
	
	export BUILD_STAMP="$( date -u "+%Y%m%d%H%M%S" )"
	
	type Prefix >/dev/null 2>&1 || \
		. "`myx.common which lib/prefix`"
	
	type Async >/dev/null 2>&1 || \
		. "`myx.common which lib/async`"
	
	DistroShellContext --distro-from-source
	
	if [ ! -d "$MDSC_SOURCE" ] ; then
		echo "ERROR: source path does not exist!" >&2
		return 1
	fi
	
	for BUILDER in $( ListAllBuilders source-prepare --1 ) ; do
		Prefix "s $( basename $BUILDER )" RebuildCachedFromSourceBuilderRaw "$BUILDER"
		wait
	done
}

BuildCachedFromSource(){
	set -e
	#### want to run in separate process anyways
	BuildCachedFromSourceRunner "$@" | cat -u
	wait
}

case "$0" in
	*/sh-scripts/BuildCachedFromSource.fn.sh) 
		BuildCachedFromSource "$@"
	;;
esac