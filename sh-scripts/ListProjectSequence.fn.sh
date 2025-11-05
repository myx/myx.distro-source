#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectSequence(){

	local MDSC_CMD='ListProjectSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	set -e

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--print-project)
				shift
				
				ListProjectSequence --project "$projectName" "$@" | sed "s|^|$projectName |g"
				return 0
			;;
			--print-declares|--print-keywords|--print-provides)
				[ -z "$2" ] || {
					echo "⛔ ERROR: $MDSC_CMD: $1, no extra options allowed:" "$@" >&2
					set +e ; return 1
				}
				local idx="${1#'--print-'}"; shift
				
				if [ -n "$MDSC_CACHED" ]; then
					if [ "$MDSC_NO_CACHE" != "--no-cache" ]; then
					
						local buildDate="$MDSC_CACHED/build-time-stamp.txt"
						local cacheFile="$MDSC_CACHED/$projectName/project-${idx}-sequence.txt"
						if [ -f "$buildDate" ]; then
							if [ -f "$cacheFile" ] && [ ! "$cacheFile" -ot "$buildDate" ]; then
								[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: --print-* using cached, ${idx} ($MDSC_OPTION)" >&2
								cat "$cacheFile"
								return 0
							fi
				
							echo "$MDSC_CMD: $projectName: --print-* caching projects, ${idx} ($MDSC_OPTION)" >&2
							DistroSystemContext --index-${idx}-merged awk -v prj="$projectName" '
								$1 == prj && !x[$3]++ { print $2, $3; }
							' | tee "$cacheFile.$$.tmp"
							mv -f -- "$cacheFile.$$.tmp" "$cacheFile" || :

							return 0
						fi

					fi
				fi			
				
				DistroSystemContext --index-${idx}-merged awk -v prj="$projectName" '
					$1 == prj && !x[$3]++ { print $2, $3; }
				'
		
				return 0
			;;
			'')
				break;
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	if [ ! -f "$MDSC_SOURCE/$projectName/project.inf" ]; then
		echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
		set +e ; return 1
	fi

	DistroSystemContext --project-index-sequence "$projectName" \
	awk '!x[$2] { print $2 }'

}

case "$0" in
	*/sh-scripts/ListProjectSequence.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectSequence.fn.sh [--no-cache] <project_name> [--print-project] [--print-provides]" >&2
			echo "📘 syntax: ListProjectSequence.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-provides" >&2
			fi
			exit 1
		fi

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectSequence "$@"
	;;
esac
