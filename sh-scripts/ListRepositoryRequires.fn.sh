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

ListRepositoryRequires(){
	if [ "$1" = "--internal-print-project-requires" ] ; then
		echo "${@:3}"  | tr ' ' '\n' | xargs -I % echo "$2" %
		return 0
	fi

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositoryRequires: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	if [ "$1" = "--print-project" ] ; then
		shift
		
		Require ListRepositorySequence
		Require ListProjectRequires

		local sequenceProjectName
		for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
			ListProjectRequires "$sequenceProjectName" "$@" | sed "s|^|$sequenceProjectName |g"
		done	
		return 0
	fi

	if [ "$1" = "--merge-sequence" ] ; then
		shift
		
		Require ListRepositorySequence
		Require ListProjectRequires

		local sequenceProjectName
		for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
			ListProjectRequires "$sequenceProjectName" --print-project "$@"
		done	
		return 0
	fi

	local useNoCache=""
	if [ "$1" = "--no-cache" ] ; then
		shift
		local useNoCache="--no-cache"
	fi

	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-requires.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListRepositoryRequires: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListRepositoryRequires: caching projects ($MDSC_OPTION)" >&2
			ListRepositoryRequires "$repositoryName" --no-cache "$@" > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListRepositoryRequires: using index ($MDSC_OPTION)" >&2
		local MTC="PRJ-REQ-$repositoryName/"
		# echo ">>>>>> MTC: $MTC" >&2
		
		grep "$MTC" "$indexFile" | sort | sed -e 's:^PRJ-REQ-::' -e 's:=: :g' | while read -r LINE ; do
			ListRepositoryRequires --internal-print-project-requires $LINE
		done
		# grep "$MTC" "$indexFile" | sort | sed -e 's:^PRJ-REQ-::' -e 's:=: :g'
		
		return 0
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
		echo "ListRepositoryRequires: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--print-requires \
			| sed "s|\:|\\\:|"
		# have ^^^ to cut project name from the beginning of each line
			
		return 0
	fi
	
	echo "ERROR: ListRepositoryRequires: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListRepositoryRequires.fn.sh)
		# ListRepositoryRequires.fn.sh lib
		# ListRepositoryRequires.fn.sh --distro-source-only lib
		# ListRepositoryRequires.fn.sh --distro-from-source lib
		# ListRepositoryRequires.fn.sh --distro-from-cached lib
		# ListRepositoryRequires.fn.sh lib --merge-sequence 2> /dev/null
		# ListRepositoryRequires.fn.sh --distro-source-only lib --merge-sequence 2> /dev/null 
		# ListRepositoryRequires.fn.sh --distro-from-source lib --merge-sequence 2> /dev/null 

		# !!!! ListRepositoryRequires.fn.sh --distro-source-only myx os-myx.common
		# !!!! ListRepositoryRequires.fn.sh --distro-from-cached myx os-myx.common
		# !!!! ListRepositoryRequires.fn.sh --distro-source-only myx deploy-keyword
		# !!!! ListRepositoryRequires.fn.sh --distro-from-cached myx deploy-keyword
		# !!!! ListRepositoryRequires.fn.sh --distro-source-only myx macosx
		# !!!! ListRepositoryRequires.fn.sh --distro-from-cached myx --merge-sequence macosx

		# !!!! ListRepositoryRequires.fn.sh ndm ndm/location-c1
		# !!!! ListRepositoryRequires.fn.sh --distro-source-only ndm ndm/location-c1
		# !!!! ListRepositoryRequires.fn.sh --distro-from-source ndm ndm/location-c1
	
		# ListRepositoryRequires.fn.sh --distro-from-source myx
		# ListRepositoryRequires.fn.sh --distro-from-cached myx
		# ListRepositoryRequires.fn.sh --distro-source-only myx
		# ListRepositoryRequires.fn.sh myx --merge-sequence 
		# !!!! ListRepositoryRequires.fn.sh myx --merge-sequence deploy-keyword
		# !!!! ListRepositoryRequires.fn.sh --distro-from-source prv --no-cache source-prepare
		# !!!! ListRepositoryRequires.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryRequires.fn.sh [--help] <repository_name> [--merge-sequence] [--no-cache] [filter_by]" >&2
			exit 1
		fi

		ListRepositoryRequires "$@"
	;;
esac