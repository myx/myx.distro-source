#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

BuildDistroFromSource(){
	set -e
	echo "BuildDistroFromSource: started: builders base directory, $MMDAPP/source $MDSC_SOURCE" >&2

	if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
		. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	fi

	local MDSC_BUILD_CONTINUE= buildOnlyLastStage=

	while true ; do
		case "$1" in
			--continue)
				MDSC_BUILD_CONTINUE=y; shift; continue
			;;
			--only|--build-distro-from-output)
				buildOnlyLastStage=y; shift; continue
			;;
			*)
				break
			;;
		esac
	done

	#### want to run in separate process anyways

	[ -n "$buildOnlyLastStage" ] || (
		DistroSystemContext --distro-from-source
		Distro BuildCachedFromSource "$@"
		Distro BuildOutputFromCached "$@"
		set -e
	)

	#### want to run in separate process anyways
	(


		RebuildDistroFromOutputBuilderRaw(){
			set -e
			
			local BUILDER="$1"
			echo "BuildDistroFromSource: $( basename $BUILDER ) builder started" >&2
			#### want to run in separate process anyways
			if ( set -e -o pipefail ; . "$MMDAPP/source/$BUILDER" ) 1>&2 ; then
				echo "BuildDistroFromSource: $( basename $BUILDER ) builder done." >&2
				return 0
			fi
			echo "⛔ ERROR: BuildDistroFromSource: $( basename $BUILDER ) failed!" >&2
			if [ -z "$MDSC_BUILD_CONTINUE" ]; then
				set +e ; return 1
			fi
			echo "⛔ ERROR: BuildDistroFromSource: --continue used, continuing after error!" >&2
		}

		set -e
		
		export BUILD_STAMP
		BUILD_STAMP="$( 
			if [ -f "$MDSC_CACHED/build-time-stamp.txt" ]; then
				date -u -r "$MDSC_CACHED/build-time-stamp.txt" "+%Y%m%d%H%M%S"
			else
				date -u "+%Y%m%d%H%M%S" 
			fi
		)"
		
		type Prefix >/dev/null 2>&1 || \
			. "$( myx.common which lib/prefix )"
		
		type Parallel >/dev/null 2>&1 || \
			. "$( myx.common which lib/parallel )"
		
		type Async >/dev/null 2>&1 || \
			. "$( myx.common which lib/async )"
		
		DistroSystemContext --distro-from-output

		if [ ! -d "$MDSC_SOURCE" ] ; then
			echo "⛔ ERROR: source path does not exist!" >&2
			set +e ; return 1
		fi
		
		Prefix "ingest-output" \
		Distro DistroImagePrepare --ingest-distro-image-from-output

		export MDSC_CACHED="$MMDAPP/.local/output-cache/distro"
		export MDSC_SOURCE="$MMDAPP/.local/source-cache/sources"
		export MDSC_OUTPUT="$MMDAPP/.local/output-cache"
		export OUTPUT_PATH="$MMDAPP/.local/output-cache/distro"
		export DISTRO_PATH="$MMDAPP/.local/output-cache/distro"
		export EXPORT_PATH="$MMDAPP/.local/output-cache/export"
		
		
		local BUILDERS="$( Distro ListAllBuilders image-prepare --3 )"
		echo 'BuildDistroFromSource: Builders list:' >&2
		printf '\t%s\n' $BUILDERS >&2
		
		for BUILDER in $BUILDERS ; do
			Prefix "s $( basename $BUILDER )" RebuildDistroFromOutputBuilderRaw "$BUILDER"
			wait
		done

		echo "BuildDistroFromSource: All Builders passed." >&2


		Prefix "populate-distro" \
		Distro DistroImagePrepare --ingest-distro-index-from-processed

		echo "BuildDistroFromSource: done." >&2

	) 1>&2
	wait || :
}

case "$0" in
	*/sh-scripts/BuildDistroFromSource.fn.sh) 
		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-source
		
		BuildDistroFromSource "$@"
	;;
esac
