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

	local useNoCache=""
	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--all)
				shift
				;;

			--filter-projects)
				shift
				filterProjects="$filterProjects --filter-projects $1" ; shift
				;;

			--filter-keywords)
				shift
				filterProjects="$filterProjects --filter-keywords $1" ; shift
				;;

			--no-cache)
				shift
				local useNoCache="--no-cache"
				;;

			'')
				break;
				;;

			*)
				echo "ListDistroSequence: invalid option: $1" >&2 ; return 1
				;;
		esac
	done

	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/distro-build-sequence.txt"
		if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListDistroSequence: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListDistroSequence: caching projects ($MDSC_OPTION)" >&2
			ListDistroSequence --all --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/distro-index.inf"
	if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListDistroSequence: using index ($MDSC_OPTION)" >&2
		local MTC="^PRJ-SEQ-"
		
		local RESULT=""
	
		if test -z "$filterProjects" ; then
			for ITEM in `grep "$MTC" "$indexFile" | sed "s,^.*=,,g" | awk '!x[$0]++'` ; do
				echo $ITEM
			done | awk '!x[$0]++'
		else
			for ITEM in `grep "$MTC" "$indexFile" | sed "s,^.*=,,g" | awk '!x[$0]++'` ; do
				if test "$ITEM" != "${ITEM#${filterProjects}:}" ; then
					echo ${ITEM#${filterProjects}:} | tr "|" "\n"
				fi
			done | awk '!x[$0]++'
		fi
		return 0
	fi
	
	if [ -z "$filterProjects" ] && [ "$MDSC_INMODE" = "source" ] ; then
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
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroSequence.fn.sh --all [--no-cache] [[--filter-projects/--filter-keywords filter_by] ...]" >&2
			echo "syntax: ListDistroSequence.fn.sh --help" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListDistroSequence.fn.sh --distro-from-source --all" >&2
				echo "	ListDistroSequence.fn.sh --distro-from-cached --all" >&2
				echo "	ListDistroSequence.fn.sh --distro-source-only --all" >&2
				echo "	ListDistroSequence.fn.sh --distro-from-source --filter-keywords deploy-l6route-config" >&2
			fi
			exit 1
		fi
		
		ListDistroSequence "$@"
	;;
esac