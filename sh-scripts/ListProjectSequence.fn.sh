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

ListProjectSequence(){

	local MDSC_CMD='ListProjectSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2 ; return 1
	fi
	shift

	set -e

	local useNoCache=""
	local useNoIndex=""

	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"

	while true ; do
		case "$1" in
			--print-project)
				shift
				
				ListProjectSequence "$projectName" $useNoCache $useNoIndex "$@" | sed "s|^|$projectName |g"
				return 0
			;;
			--print-provides)
				shift
				
				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoCache" != "--no-cache" ] ; then
						local cacheFile="$MDSC_CACHED/$projectName/project-provides-sequence.txt"
						if [ -f "$cacheFile" ] && \
							( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
						then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: --print-provides using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						Require ListProjectProvides
						
						echo "$MDSC_CMD: $projectName: --print-provides caching projects ($MDSC_OPTION)" >&2
						for sequenceProjectName in $( ListProjectSequence "$projectName" $useNoCache $useNoIndex ) ; do
							ListProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex --print-project "$@"
						done | awk '!x[$2]++' | tee "$cacheFile"
						return 0
					fi
				fi			
				
				
				Require ListProjectProvides
		
				for sequenceProjectName in $( ListProjectSequence "$projectName" $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex --print-project "$@"
				done | awk '!x[$2]++'
				# ListProjectSequence "$projectName" $useNoCache $useNoIndex "$@" | sed "s|^|$projectName |g"
				return 0
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
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2 ; return 1
			;;
		esac
	done


	if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$projectName/project-build-sequence.txt"
			if [ -f "$cacheFile" ] && \
				( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi

			if [ ! -d "$MDSC_CACHED/$projectName" ] ; then
				echo "$MDSC_CMD: $projectName: bypass ($MDSC_OPTION)" >&2
				ListProjectSequence "$projectName" --no-cache
				return 0
			fi

			echo "$MDSC_CMD: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectSequence "$projectName" --no-cache | tee "$cacheFile"
			return 0
		fi

		if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
			if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
				echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
				
				local FILTER="$1"
				local currentProject
				if [ -z "$FILTER" ] ; then
					for currentProject in ` grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed 's|^.*=||g' ` ; do
						echo $currentProject
					done
				else
					for currentProject in ` grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed 's|^.*=||g' ` ; do
						if [ "$currentProject" != "${currentProject#${FILTER}:}" ] ; then
							echo ${currentProject#${FILTER}:} | tr "|" "\n"
						fi
					done
				fi
				return 0
			fi
		fi
	fi
	
	
	if [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--select-required \
			--print-sequence
		return 0
	fi
	
	echo "ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectSequence.fn.sh) 
		# ListProjectSequence.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectSequence.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectSequence.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectSequence.fn.sh <project_name> [--print-project] [--no-cache] [--print-provides]" >&2
			echo "syntax: ListProjectSequence.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-provides" >&2
			fi
			exit 1
		fi

		ListProjectSequence "$@"
	;;
esac