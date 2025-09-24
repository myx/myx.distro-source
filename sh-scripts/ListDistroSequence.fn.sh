#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

ListDistroSequence(){
	local MDSC_CMD='ListDistroSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--all)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
						local cacheFile="$MDSC_CACHED/distro-build-sequence.txt"
						local buildDate="$MDSC_CACHED/build-time-stamp.txt"
						if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi

						echo "$MDSC_CMD: caching projects ($MDSC_OPTION)" >&2

						ListDistroSequence --no-cache --all | tee "$cacheFile.$$.tmp"
						mv "$cacheFile.$$.tmp" "$cacheFile"

						return 0
					fi
					
					local indexFile="$MDSC_CACHED/distro-index.inf"
					if [ "$MDSC_NO_INDEX" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
							
							echo "$MDSC_CMD: --all using index ($MDSC_OPTION)" >&2
							
							for ITEM in ` grep "^PRJ-SEQ-" "$indexFile" | sed 's|^.*=||g' | awk '!x[$0]++' ` ; do
								echo $ITEM
							done | awk '!x[$0]++'

							return 0
						fi
					fi
				fi
				
				if [ -z "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ "$MDSC_INMODE" = "source" ] ; then
					echo "$MDSC_CMD: --all extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					DistroSourceCommand \
						-q \
						--import-from-source \
						--select-all \
						--select-required \
						--print-sequence
					return 0
				fi
				
				echo "⛔ ERROR: $MDSC_CMD: can't list distro sequence (mode: $MDSC_INMODE)" >&2
				set +e ; return 1
				;;

			--all-projects)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-projects option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					
					local indexFile="$MDSC_CACHED/distro-index.inf"
					if [ "$MDSC_NO_INDEX" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
							
							echo "$MDSC_CMD: --all-projects using index ($MDSC_OPTION)" >&2

							local sequenceProject
							local projectSequence
							local currentProject

							grep -e "^PRJ-SEQ-" "$indexFile" \
							| sed -e 's:^PRJ-SEQ-::' -e 's:=: :g' -e 's|\\:|:|g' \
							| while read -r sequenceProject projectSequence ; do
								for currentProject in $projectSequence ; do
									echo "$sequenceProject" "$currentProject"
								done
							done | awk '!x[$0]++'
							return 0
						fi
					fi
				fi
				
				if [ -z "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ "$MDSC_INMODE" = "source" ] ; then
					echo "$MDSC_CMD: --all-projects extracting from source (java) ($MDSC_OPTION)" >&2
			
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
				for sequenceProjectName in $( ListDistroSequence --all ) ; do
					ListProjectSequence "$sequenceProjectName" | while read -r currentProjectName ; do
						echo "$sequenceProjectName" "$currentProjectName"
					done
				done
				return 0
				;;

			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
				;;
		esac
	done


}

case "$0" in
	*/sh-scripts/ListDistroSequence.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListDistroSequence.fn.sh [<options>] --all" >&2
			echo "📘 syntax: ListDistroSequence.fn.sh [<options>] --all-projects" >&2
			echo "📘 syntax: ListDistroSequence.fn.sh --help" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListDistroSequence.include"
			fi
			exit 1
		fi
		
		ListDistroSequence "$@"
	;;
esac
