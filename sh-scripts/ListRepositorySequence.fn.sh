#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListRepositorySequence(){
	
	local MDSC_CMD='ListRepositorySequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local repositoryName=""

	set -e

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--help|--help-syntax)
				echo "syntax: ListRepositorySequence.fn.sh [--no-cache] <repositoryName>" >&2
				echo "syntax: ListRepositorySequence.fn.sh --help" >&2
				if [ "$1" = "--help" ] ; then
					. "$MMDAPP/source/myx/myx.distro-source/sh-lib/help/HelpListRepositorySequence.include"
				fi
				return 0
			;;
			--*)
				echo "⛔ ERROR: ListRepositorySequence: invalid option: $1" >&2
				set +e ; return 1
				;;
			'')
				break;
				;;
			*)
				repositoryName="$1" ; shift
				;;
		esac
	done

	if [ -z "$repositoryName" ] ; then
		echo "⛔ ERROR: ListRepositorySequence: 'repositoryName' argument is required!" >&2
		set +e ; return 1
	fi

	if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-build-sequence.txt"
		if [ -n "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListRepositorySequence: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListRepositorySequence: caching projects ($MDSC_OPTION)" >&2
			ListRepositorySequence --no-cache "$repositoryName" | tee "$cacheFile"
			return 0
		fi
	fi
	
	if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
		local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
		if [ -n "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			
			echo "ListRepositorySequence: using index ($MDSC_OPTION)" >&2
			
			local FILTER="$1"
			local currentProject
			if [ -z "$FILTER" ] ; then
				for currentProject in ` grep "^PRJ-SEQ-$repositoryName/" "$indexFile" | sed 's|^.*=||g' | awk '!x[$0]++' ` ; do
					echo $currentProject
				done | awk '!x[$0]++'
			else
				for currentProject in ` grep "^PRJ-SEQ-$repositoryName/" "$indexFile" | sed 's|^.*=||g' | awk '!x[$0]++' ` ; do
					if [ "$currentProject" != "${currentProject#${FILTER}:}" ] ; then
						echo ${currentProject#${FILTER}:} | tr "|" "\n"
					fi
				done | awk '!x[$0]++'
			fi
			return 0
		fi
	fi
	
	if [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
		echo "ListRepositorySequence: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--select-required \
			--print-sequence
		return 0
	fi
	
	echo "⛔ ERROR: ListRepositorySequence: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListRepositorySequence.fn.sh) 
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			ListRepositorySequence ${1:-"--help-syntax"}
			exit 1
		fi

		ListRepositorySequence "$@"
	;;
esac
