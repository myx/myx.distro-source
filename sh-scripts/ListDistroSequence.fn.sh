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

ListDistroSequence(){
	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/distro-build-sequence.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListDistroSequence: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListDistroSequence: caching projects ($MDSC_OPTION)" >&2
			ListDistroSequence --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/distro-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListDistroSequence: using index ($MDSC_OPTION)" >&2
		local MTC="^PRJ-SEQ-"
		
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
	
	if [ "$MDSC_INMODE" = "source" ] ; then
		echo "ListDistroSequence: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-all \
			--select-required \
			--print-sequence
		return 0
	fi
	
	echo "ListDistroSequence: can't list distro sequence (mode: $MDSC_INMODE)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListDistroSequence.fn.sh) 
		# ListDistroSequence.fn.sh --distro-source-only myx 2> /dev/null
		# ListDistroSequence.fn.sh --distro-from-source myx 2> /dev/null
		# ListDistroSequence.fn.sh --distro-from-cached myx 2> /dev/null

		ListDistroSequence "$@"
	;;
esac