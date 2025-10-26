#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

BuildOutputFromCached(){
	set -e
	echo "BuildOutputFromCached: started: builders base directory, $MMDAPP/source $MDSC_SOURCE" >&2

	if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
		. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	fi

	Require ListDistroProjects
	Require ListAllBuilders

	local MDSC_BUILD_CONTINUE=

	while true ; do
		case "$1" in
			--continue)
				MDSC_BUILD_CONTINUE=y; shift; continue
			;;
			*)
				break
			;;
		esac
	done

	#### want to run in separate process anyways
	(

		RebuildOutputFromCachedBuilderRaw(){
			set -e
			
			local BUILDER="$1"
			echo "BuildOutputFromCached: $( basename $BUILDER ) builder started" >&2
			#### want to run in separate process anyways
			if ( set -e -o pipefail ; . "$MMDAPP/source/$BUILDER" ) 1>&2 ; then
				echo "BuildOutputFromCached: $( basename $BUILDER ) builder done." >&2
				return 0
			fi
			echo "⛔ ERROR: BuildOutputFromCached: $( basename $BUILDER ) failed!" >&2
			if [ -z "$MDSC_BUILD_CONTINUE" ]; then
				set +e ; return 1
			fi
			echo "⛔ ERROR: BuildOutputFromCached: --continue used, continuing after error!" >&2
		}

		set -e

		export BUILD_STAMP
		BUILD_STAMP="$( 
			[ -z "$MDSC_CACHED/build-time-stamp.txt" ] \
			&& date -u -r "$MDSC_CACHED/build-time-stamp.txt" "+%Y%m%d%H%M%S" \
			|| date -u "+%Y%m%d%H%M%S" 
		)"
		
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

		Prefix "ingest-cached" \
		Distro DistroSourceProcess --ingest-distro-output-from-cached

		export MDSC_SOURCE="$MMDAPP/.local/source-cache/sources"
		export MDSC_CACHED="$MMDAPP/.local/output-cache/prepared"
		export MDSC_OUTPUT="$MMDAPP/.local/output-cache"
		export OUTPUT_PATH="$MMDAPP/.local/output-cache/output"

		local BUILDERS
		BUILDERS="$( ListAllBuilders source-process --2 )"
		echo 'BuildOutputFromCached: Builders list:' >&2
		printf '\t%s\n' $BUILDERS >&2
		
		for BUILDER in $BUILDERS ; do
			Prefix "c $( basename $BUILDER )" RebuildOutputFromCachedBuilderRaw "$BUILDER"
			wait
		done

		echo "BuildOutputFromCached: All Builders passed." >&2

		Prefix "populate-processed" \
		Distro DistroSourceProcess --ingest-distro-index-from-processed

		echo "BuildOutputFromCached: done." >&2

	) 1>&2
	wait || :
}

case "$0" in
	*/sh-scripts/BuildOutputFromCached.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-cached
		
		BuildOutputFromCached "$@"
	;;
esac
