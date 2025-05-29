#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
fi

Require ListAllRepositories
Require ListDistroProjects
Require ListDistroBuilders


RebuildCachedFromSourceBuilderRaw(){
	set -e
	
	local BUILDER="$1"
	echo "BuildCachedFromSource: $( basename $BUILDER ) builder started" >&2
	#### want to run in separate process anyways
	if ( . "$MMDAPP/source/$BUILDER" | cat -u ) ; then
		echo "BuildCachedFromSource: $( basename $BUILDER ) builder done." >&2
	else
		echo "ERROR: BuildCachedFromSource: $( basename $BUILDER ) failed!" >&2
		set +e ; return 1
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
	
	local BUILDERS="$( ListDistroBuilders source-prepare --1 )"
	echo "BuildCachedFromSource: Builders list:" $BUILDERS >&2
	
	for BUILDER in $BUILDERS ; do
		Prefix "s $( basename $BUILDER )" RebuildCachedFromSourceBuilderRaw "$BUILDER"
		wait
	done

	echo "BuildCachedFromSource: All Builders passed." >&2
}

BuildCachedFromSource(){
	set -e
	echo "BuildCachedFromSource: started: builders base directory, $MMDAPP/source $MDSC_SOURCE" >&2
	#### want to run in separate process anyways
	BuildCachedFromSourceRunner "$@" | cat -u
	wait || true
}

case "$0" in
	*/sh-scripts/BuildCachedFromSource.fn.sh) 
		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-from-source
		
		BuildCachedFromSource "$@"
	;;
esac
