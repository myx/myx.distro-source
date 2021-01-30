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

ListProjectRequires(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ERROR: ListProjectRequires: 'projectName' argument is required!" >&2 ; return 1
	fi
	shift

	if [ "$1" = "--merge-sequence" ] ; then
		shift
		
		( \
			Require ListProjectSequence
			
			for sequenceProjectName in $( ListProjectSequence "$projectName" ) ; do
				ListProjectRequires "$sequenceProjectName" "$@"
			done	
		) | awk '!x[$0]++'		
		return 0
	fi

	if [ "$1" = "--print-project" ] ; then
		shift
		ListProjectRequires "$projectName" "$@" | sed "s|^|$projectName |g"
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
		for ITEM in $( ListProjectRequires "$projectName" $useNoCache "$@" ) ; do
			if test "$ITEM" != "${ITEM#${FILTER}:}" ; then
				echo ${ITEM#${FILTER}:} | tr '|' '\n' 
			fi
		done
		return 0
	fi
	
	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$projectName/project-requires.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListProjectRequires: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListProjectRequires: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectRequires "$projectName" --no-cache "$@" | tee "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListProjectRequires: $projectName: using index ($MDSC_OPTION)" >&2
		local MTC="PRJ-REQ-$projectName="
		# echo ">>>>>> MTC: $MTC"
		
		for LINE in $( grep "$MTC" "$indexFile" | sed "s:^.*=::g" | sort ) ; do
			echo $LINE
		done
		# grep "$MTC" "$indexFile" | sed "s:^.*=::g" | sort
		
		return 0
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "ListProjectRequires: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--print-requires \
			| sed "s|^$projectName ||g" \
			| sed "s|\:|\\\:|"
		# have ^^^ to cut project name from the beginning of each line
			
		return 0
	fi
	
	echo "ERROR: ListProjectRequires: $projectName: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectRequires.fn.sh)
		# ListProjectRequires.fn.sh --distro-from-source myx/myx.distro-deploy 2> /dev/null
		# ListProjectRequires.fn.sh --distro-source-only myx/myx.distro-deploy 2> /dev/null
		# ListProjectRequires.fn.sh --distro-from-source myx/myx.distro-deploy --print-project 2> /dev/null
		# ListProjectRequires.fn.sh --distro-source-only myx/myx.distro-deploy --print-project 2> /dev/null
		# ListProjectRequires.fn.sh --distro-from-source myx/myx.distro-deploy --merge-sequence 2> /dev/null 
		# ListProjectRequires.fn.sh --distro-source-only myx/myx.distro-deploy --merge-sequence 2> /dev/null 
		# ListProjectRequires.fn.sh --distro-from-source myx/myx.distro-deploy --print-project --merge-sequence 2> /dev/null 
		# ListProjectRequires.fn.sh --distro-source-only myx/myx.distro-deploy --print-project --merge-sequence 2> /dev/null 
		# ListProjectRequires.fn.sh --distro-from-source myx/myx.distro-deploy --merge-sequence --print-project 2> /dev/null 
		# ListProjectRequires.fn.sh --distro-source-only myx/myx.distro-deploy --merge-sequence --print-project 2> /dev/null 
		# ListProjectRequires.fn.sh myx/myx.distro-deploy
		
		# ListProjectRequires.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz --merge-sequence --print-project 2> /dev/null 
		# ListProjectRequires.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz --print-project --merge-sequence 
		
		# !!!! ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --print-project setup-keys.ndm.myx
		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence setup-keys.ndm.myx 2> /dev/null
		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence --print-project setup-keys.ndm.myx
		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --print-project --merge-sequence setup-keys.ndm.myx

		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project 2> /dev/null
		# ListProjectRequires.fn.sh --distro-source-only ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project 2> /dev/null
		# ListProjectRequires.fn.sh --distro-from-cached ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project 2> /dev/null
		# ListProjectRequires.fn.sh --distro-from-source ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project 2> /dev/null
	
		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project setup-keys.ndm.myx 2> /dev/null
		# ListProjectRequires.fn.sh ndm/cloud.knt/setup.host-captive1-c1.ndm9.xyz --merge-sequence --print-project setup-keys.ndm.myx 2> /dev/null
	
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectRequires.fn.sh [--help] <project_name> [--merge-sequence] [--print-project] [--no-cache] [filter_by]" >&2
			exit 1
		fi
		
		ListProjectRequires "$@"
	;;
esac