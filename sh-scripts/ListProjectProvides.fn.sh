#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && return 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-default
fi

ListProjectProvides(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ERROR: ListProjectProvides: 'projectName' argument is required!" >&2 ; return 1
	fi
	shift

	if [ "$1" = "--merge-sequence" ] ; then
		shift
		
		( \
			Require ListProjectSequence
			
			for sequenceProjectName in $( ListProjectSequence "$projectName" ) ; do
				ListProjectProvides "$sequenceProjectName" "$@"
			done	
		) | uniq		
		return 0
	fi

	if [ "$1" = "--print-project" ] ; then
		shift
		ListProjectProvides "$projectName" "$@" | sed "s|^|$projectName |g"
		return 0
	fi

	local useNoCache=""
	if [ "$1" = "--no-cache" ] ; then
		shift
		local useNoCache="--no-cache"
	fi

	local FILTER="$1"
	if [ ! -z "$FILTER" ] ; then
		shift
		for ITEM in $( ListProjectProvides "$projectName" $useNoCache "$@" ) ; do
			if test "$ITEM" != "${ITEM#$FILTER\\:}" ; then
				echo ${ITEM#$FILTER\\:} | tr '|' '\n' 
			fi
		done
		return 0
	fi
	
	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$projectName/project-provides.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			echo "ListProjectProvides: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListProjectProvides: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectProvides "$projectName" --no-cache "$@" > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListProjectProvides: $projectName: using index ($MDSC_OPTION)" >&2
		local MTC="PRJ-PRV-$projectName="
		# echo ">>>>>> MTC: $MTC"
		
		for LINE in $( cat "$indexFile" | grep "$MTC" | sed "s:^.*=::g" | sort ) ; do
			echo $LINE
		done
		# cat "$indexFile" | grep "$MTC" | sed "s:^.*=::g" | sort
		
		return 0
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "ListProjectProvides: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--print-provides \
			| sed "s|^$projectName ||g" \
			| sed "s|\:|\\\:|"
		# have ^^^ to cut project name from the beginning of each line
			
		return 0
	fi
	
	echo "ERROR: ListProjectProvides: $projectName: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectProvides.fn.sh)
		# ListProjectProvides.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectProvides.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectProvides.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz 
		# ListProjectProvides.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz --merge-sequence --print-project 
		# ListProjectProvides.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --print-project deploy-keyword
		# ListProjectProvides.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence deploy-keyword
		# ListProjectProvides.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence --print-project deploy-keyword

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectProvides.fn.sh [--help] <project_name> [--merge-sequence] [--print-project] [--no-cache] [filter_by]" >&2
			return 1
		fi
		
		ListProjectProvides "$@"
	;;
esac