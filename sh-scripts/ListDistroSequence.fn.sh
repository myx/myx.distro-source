#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
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
					echo "⛔ ERROR: $MDSC_CMD: --all. no extra options allowed" >&2
					set +e ; return 1
				fi

				if [ "$MDSC_NO_CACHE" != "--no-cache" ] && [ -d "$MDSC_CACHED" ] ; then
					local buildDate="$MDSC_CACHED/build-time-stamp.txt"
					if [ -f "$buildDate" ]; then
						local cacheFile="$MDSC_CACHED/distro-build-sequence.txt"
						if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi

						echo "| $MDSC_CMD: --all, build sequence, caching projects ($MDSC_OPTION)" >&2
						. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListBuildSequenceNoCache.include" \
						| tee "$cacheFile.$$.tmp"
						mv -f "$cacheFile.$$.tmp" "$cacheFile" || :
						return 0
					fi
				fi

				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListBuildSequenceNoCache.include"
				return 0
				;;

			--all-projects)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --all-projects. no extra options allowed" >&2
					set +e ; return 1
				fi

				if [ "$MDSC_NO_CACHE" != "--no-cache" ] && [ -d "$MDSC_CACHED" ] ; then
					local buildDate="$MDSC_CACHED/build-time-stamp.txt"
					if [ -f "$buildDate" ]; then
						local cacheFile="$MDSC_CACHED/distro-sequences.txt"
						if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-projects using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi

						echo "| $MDSC_CMD: --all-projects, build sequence, caching ($MDSC_OPTION)" >&2
						. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListAllSequencesNoCache.include" \
						| tee "$cacheFile.$$.tmp"
						mv -f "$cacheFile.$$.tmp" "$cacheFile" || :
						return 0
					fi
				fi

				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListAllSequencesNoCache.include"
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
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListDistroSequence "$@"
	;;
esac
