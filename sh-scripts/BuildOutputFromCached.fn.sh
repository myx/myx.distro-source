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

Require ListDistroProjects
Require ListDistroBuilders


RebuildOutputFromCachedBuilderRaw(){
	set -e
	
	local BUILDER="$1"
	echo "BuildOutputFromCached: $( basename $BUILDER ) builder started" >&2
	#### want to run in separate process anyways
	if ( set -e -o pipefail ; . "$MMDAPP/source/$BUILDER" | tee /dev/stderr >/dev/null ) ; then
		echo "BuildOutputFromCached: $( basename $BUILDER ) builder done." >&2
	else
		echo "⛔ ERROR: BuildOutputFromCached: $( basename $BUILDER ) failed!" >&2
		set +e ; return 1
	fi
}

BuildOutputFromCachedRunner(){
	set -e
	
	export BUILD_STAMP="$( date -u "+%Y%m%d%H%M%S" )"
	
	type Prefix >/dev/null 2>&1 || \
		. "$( myx.common which lib/prefix )"
	
	type Parallel >/dev/null 2>&1 || \
		. "$( myx.common which lib/parallel )"
	
	type Async >/dev/null 2>&1 || \
		. "$( myx.common which lib/async )"
	
	DistroSystemContext --distro-from-cached
	
	if [ ! -d "$MDSC_SOURCE" ] ; then
		echo "⛔ ERROR: source path does not exist!" >&2
		set +e ; return 1
	fi
	
	export OUTPUT_PATH="$MMDAPP/output"

	local BUILDERS="$( ListDistroBuilders source-process --2 )"
	echo 'BuildOutputFromCached: Builders list:' >&2
	printf '\t%s\n' $BUILDERS >&2
	
	for BUILDER in $BUILDERS ; do
		Prefix "c $( basename $BUILDER )" RebuildOutputFromCachedBuilderRaw "$BUILDER"
		wait
	done

	echo "BuildOutputFromCached: All Builders passed." >&2
}

BuildOutputFromCached(){
	set -e
	echo "BuildOutputFromCached: started: builders base directory, $MMDAPP/source $MDSC_SOURCE" >&2
	#### want to run in separate process anyways
	BuildOutputFromCachedRunner "$@" | cat -u
	wait
}

case "$0" in
	*/sh-scripts/BuildOutputFromCached.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-cached
		
		BuildOutputFromCached "$@"
	;;
esac
