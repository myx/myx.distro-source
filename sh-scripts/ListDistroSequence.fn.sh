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

ListDistroSequence(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListDistroSequence $@" >&2

	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--all|--all-projects)
				break
				;;

			--no-cache)
				shift
				local useNoCache="--no-cache"
				;;

			--no-index)
				shift
				local useNoIndex="--no-index"
				;;

			*)
				echo "ERROR: ListDistroSequence: invalid option: $1" >&2 ; return 1
				;;
		esac
	done

	case "$1" in
		--all)
			shift
			if [ ! -z "$1" ] ; then
				echo "ERROR: ListDistroSequence: no options allowed after --all option ($MDSC_OPTION, $@)" >&2
				return 1
			fi

			if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
				if [ "$useNoCache" != "--no-cache" ] ; then
					local cacheFile="$MDSC_CACHED/distro-build-sequence.txt"

					if [ -f "$cacheFile" ] && \
						( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
					then
						[ -z "$MDSC_DETAIL" ] || echo "| ListDistroSequence: --all using cached ($MDSC_OPTION)" >&2
						cat "$cacheFile"
						return 0
					fi

					echo "ListDistroSequence: caching projects ($MDSC_OPTION)" >&2

					ListDistroSequence --no-cache --all > "$cacheFile"
					cat "$cacheFile"

					return 0
				fi
				
				local indexFile="$MDSC_CACHED/distro-index.inf"
				if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
					if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						echo "ListDistroSequence: --all using index ($MDSC_OPTION)" >&2
						
						for ITEM in `grep "^PRJ-SEQ-" "$indexFile" | sed "s,^.*=,,g" | awk '!x[$0]++'` ; do
							echo $ITEM
						done | awk '!x[$0]++'

						return 0
					fi
				fi
			fi
			
			if [ "$MDSC_INMODE" = "source" ] ; then
				echo "ListDistroSequence: --all extracting from source (java) ($MDSC_OPTION)" >&2
		
				Require DistroSourceCommand
				
				DistroSourceCommand \
					-q \
					--import-from-source \
					--select-all \
					--select-required \
					--print-sequence
				return 0
			fi
			
			echo "ERROR: ListDistroSequence: can't list distro sequence (mode: $MDSC_INMODE)" >&2 ; return 1
			;;

		--all-projects)
			shift
			if [ ! -z "$1" ] ; then
				echo "ERROR: ListDistroSequence: no options allowed after --all-projects option ($MDSC_OPTION, $@)" >&2
				return 1
			fi

			if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
				
				local indexFile="$MDSC_CACHED/distro-index.inf"
				if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
					if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						echo "ListDistroSequence: --all-projects using index ($MDSC_OPTION)" >&2

						local sequenceProject
						local projectSequence
						local currentProject

						echo "` \
							grep -e "^PRJ-SEQ-" "$indexFile" | sed -e 's:^PRJ-SEQ-::' -e 's:=: :g' -e 's|\\:|:|g' \
						`" | while read -r sequenceProject projectSequence ; do
							for currentProject in $projectSequence ; do
								echo "$sequenceProject" "$currentProject"
							done
						done | awk '!x[$0]++'
						return 0
					fi
				fi
			fi
			
			if [ "$MDSC_INMODE" = "source" ] ; then
				echo "ListDistroProvides: --all-provides extracting from source (java) ($MDSC_OPTION)" >&2
		
				Require DistroSourceCommand
				
				DistroSourceCommand \
					-q \
					--import-from-source \
					--select-all \
					--print-sequence-separate-lines
					
				return 0
			fi
			
			Require ListDistroSequence
			Require ListProjectSequence

			local sequenceProjectName
			local currentProjectName
			for sequenceProjectName in $( ListDistroSequence $useNoCache $useNoIndex --all ) ; do
				ListProjectSequence "$sequenceProjectName" $useNoCache $useNoIndex | while read -r currentProjectName ; do
					echo "$sequenceProjectName" "$currentProjectName"
				done
			done
			return 0
			;;
	esac

}

case "$0" in
	*/sh-scripts/ListDistroSequence.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroSequence.fn.sh --all [--no-cache]" >&2
			echo "syntax: ListDistroSequence.fn.sh --help" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListDistroSequence.fn.sh --distro-from-source --all" >&2
				echo "	ListDistroSequence.fn.sh --distro-from-cached --all" >&2
				echo "	ListDistroSequence.fn.sh --distro-source-only --all" >&2
			fi
			exit 1
		fi
		
		ListDistroSequence "$@"
	;;
esac