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
				echo "📘 syntax: ListRepositorySequence.fn.sh [--no-cache] <repositoryName>" >&2
				echo "📘 syntax: ListRepositorySequence.fn.sh --help" >&2
				if [ "$1" = "--help" ] ; then
					. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpListRepositorySequence.include"
				fi
				return 0
			;;
			--*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
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
		echo "⛔ ERROR: $MDSC_CMD: 'repositoryName' argument is required!" >&2
		set +e ; return 1
	fi

	if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-build-sequence.txt"
		local buildDate="$MDSC_CACHED/build-time-stamp.txt"
		if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "$MDSC_CMD: caching projects ($MDSC_OPTION)" >&2
			mkdir -p "$MDSC_CACHED/$repositoryName"
			ListRepositorySequence --no-cache "$repositoryName" | tee "$cacheFile.$$.tmp"
			mv -f "$cacheFile.$$.tmp" "$cacheFile" || :
			return 0
		fi
	fi
	
	if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
		local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
		if [ -n "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			
			echo "$MDSC_CMD: using index ($MDSC_OPTION)" >&2
			
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
	
	if [ -z "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ -f "$MMDAPP/.local/roots/$repositoryName.distro-namespace" ] ; then
		echo "$MDSC_CMD: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--select-required \
			--print-sequence
		return 0
	fi
	
	echo "⛔ ERROR: $MDSC_CMD: project.inf file is required (at: $indexFile)" >&2
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
