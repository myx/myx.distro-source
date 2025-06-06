#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListRepositorySequence(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListRepositorySequence $@" >&2

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositorySequence: 'repositoryName' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--all)
				shift
				;;

			--no-cache)
				shift
				local useNoCache="--no-cache"
				;;
			
			--no-index)
				shift
				local useNoIndex="--no-index"
				;;

			'')
				break;
				;;

			*)
				echo "ERROR: ListRepositorySequence: invalid option: $1" >&2
				set +e ; return 1
				;;
		esac
	done

	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-build-sequence.txt"
		if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListRepositorySequence: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListRepositorySequence: caching projects ($MDSC_OPTION)" >&2
			ListRepositorySequence "$repositoryName" --no-cache | tee "$cacheFile"
			return 0
		fi
	fi
	
	if [ "$useNoIndex" != "--no-index" ] ; then
		local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
		if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
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
	
	if [ -z "$filterProjects" ] && [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
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
	
	echo "ERROR: ListRepositorySequence: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListRepositorySequence.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositorySequence.fn.sh <repositoryName> [--no-cache]" >&2
			echo "syntax: ListRepositorySequence.fn.sh --help" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Options:" >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "	ListRepositorySequence.fn.sh myx" >&2
				echo "	ListRepositorySequence.fn.sh --distro-from-source myx 2> /dev/null" >&2
				echo "	ListRepositorySequence.fn.sh --distro-from-cached myx 2> /dev/null" >&2
				echo "	ListRepositorySequence.fn.sh --distro-source-only myx 2> /dev/null" >&2
			fi
			exit 1
		fi

		ListRepositorySequence "$@"
	;;
esac
