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

ListRepositorySequence(){
	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ListRepositorySequence: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/$repositoryName/repository-build-sequence.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListRepositorySequence: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListRepositorySequence: caching projects ($MDSC_OPTION)" >&2
			ListRepositorySequence "$repositoryName" --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListRepositorySequence: using index ($MDSC_OPTION)" >&2
		local MTC="PRJ-SEQ-$repositoryName/"
		
		local RESULT=""
	
		local FILTER="$1"
		if test -z "$FILTER" ; then
			for ITEM in `cat "$indexFile" | grep "$MTC" | sed "s,^.*=,,g" | awk '!x[$0]++'` ; do
				echo $ITEM
			done | awk '!x[$0]++'
		else
			for ITEM in `cat "$indexFile" | grep "$MTC" | sed "s,^.*=,,g" | awk '!x[$0]++'` ; do
				if test "$ITEM" != "${ITEM#$FILTER\\:}" ; then
					echo ${ITEM#$FILTER\\:} | tr "|" "\n"
				fi
			done | awk '!x[$0]++'
		fi
		return 0
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
	
	echo "ListRepositorySequence: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListRepositorySequence.fn.sh) 
		# ListRepositorySequence.fn.sh --distro-source-only myx 2> /dev/null
		# ListRepositorySequence.fn.sh --distro-from-source myx 2> /dev/null
		# ListRepositorySequence.fn.sh --distro-from-cached myx 2> /dev/null

		ListRepositorySequence "$@"
	;;
esac