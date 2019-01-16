#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && return 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListRepositoryProvides(){
	if [ "$1" = "--internal-print-project-provides" ] ; then
		shift
		if [ "$1" = "--filter" ] ; then
			shift
			local FILTER="$1" ; shift
			local projectName="$1" ; shift
			for ITEM in "$@" ; do
				if test "$ITEM" != "${ITEM#$FILTER\\:}" ; then
					echo "$projectName ${ITEM#$FILTER\\:}" | tr '|' '\n' 
				fi
			done
			return 0
		fi
		local projectName="$1" ; shift
		for ITEM in "$@" ; do
			echo "$projectName $ITEM"
		done
		return 0
	fi

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositoryProvides: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	local useNoCache=""

	set -e

	while true ; do
		case "$1" in
			--print-project)
				shift
				
				Require ListRepositorySequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
					ListProjectProvides "$sequenceProjectName" "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
				;;
			--filter-projects)
				shift
				local projectFilter="$1" ; shift
				# echo ">>>" $repositoryName ">>>" $projectFilter >&2
				# set -x
				ListRepositoryProvides "$repositoryName" "$@" | grep -e "^.*$projectFilter.* "
				return 0
				;;
			--merge-sequence)
				shift
				
				Require ListRepositorySequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
					ListProjectProvides "$sequenceProjectName" --print-project "$@"
				done	
				return 0
				;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
				;;
			*)
				break
				;;
		esac
	done

	local FILTER="$1"
	if [ ! -z "$FILTER" ] ; then
		shift
		for LINE in $( ListRepositoryProvides "$repositoryName" $useNoCache "$@" | myx.common lib/linesToArguments ) ; do
			ListRepositoryProvides --internal-print-project-provides --filter "$FILTER" $LINE
		done
		return 0
		for ITEM in $( ListRepositoryProvides "$repositoryName" $useNoCache "$@" ) ; do
			if test "$ITEM" != "${ITEM#$FILTER\\:}" ; then
				echo ${ITEM#$FILTER\\:} | tr '|' '\n' 
			fi
		done
		return 0
	fi
	
	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-provides.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListRepositoryProvides: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListRepositoryProvides: caching projects ($MDSC_OPTION)" >&2
			ListRepositoryProvides $repositoryName --no-cache "$@" > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListRepositoryProvides: using index ($MDSC_OPTION)" >&2
		local MTC="PRJ-PRV-$repositoryName/"
		# echo ">>>>>> MTC: $MTC" >&2
		
		cat "$indexFile" | grep "$MTC" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' | while read -r LINE ; do
			ListRepositoryProvides --internal-print-project-provides $LINE
		done
		# cat "$indexFile" | grep "$MTC" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g'
		
		return 0
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
		echo "ListRepositoryProvides: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--print-provides \
			| sed "s|\:|\\\:|"
		# have ^^^ to cut project name from the beginning of each line
			
		return 0
	fi
	
	echo "ERROR: ListRepositoryProvides: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListRepositoryProvides.fn.sh)
		# ListRepositoryProvides.fn.sh --distro-from-source myx
		# ListRepositoryProvides.fn.sh --distro-source-only myx
		# ListRepositoryProvides.fn.sh myx --merge-sequence 
		# ListRepositoryProvides.fn.sh myx deploy-keyword
		# ListRepositoryProvides.fn.sh myx --merge-sequence deploy-keyword
		# ListRepositoryProvides.fn.sh --distro-from-source prv --no-cache source-prepare
		# ListRepositoryProvides.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryProvides.fn.sh [--help] <repository_name> [--merge-sequence] [--no-cache] [filter_by]" >&2
			exit 1
		fi

		ListRepositoryProvides "$@"
	;;
esac