#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectDeclares(){

	local MDSC_CMD='ListProjectDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	set -e

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	local filterProjects=""

	while true ; do
		case "$1" in
			--print-declares-only)
				shift
				ListProjectDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX "$projectName" "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break
				#ListProjectDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX "$projectName" "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" projectDeclares ; shift

				ListProjectDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX "$projectName" "$@" --print-declares-only \
				| while read -r projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListProjectSequence

				if [ -z "$1" ] ; then
					ListProjectSequence "$projectName" --print-declares
					return 0
				fi

				local sequenceProjectName
				ListProjectSequence "$projectName" \
				| while read -r sequenceProjectName ; do
					ListProjectDeclares "$sequenceProjectName" "$@"
				done | awk '!x[$0]++'	
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

	if [ -d "$MDSC_CACHED" ] ; then
		if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
			local buildDate="$MDSC_CACHED/build-time-stamp.txt"
			local cacheFile="$MDSC_CACHED/$projectName/project-declares.txt"

			[ -f "$buildDate" ] || date -u "+%Y%m%d%H%M%S" > "$buildDate"

			if [ -f "$cacheFile" ]; then
				if { [ -n "$BUILD_STAMP" ] && [ ! "$BUILD_STAMP" -gt "$( date -u -r "$cacheFile" "+%Y%m%d%H%M%S" )" ]; } \
				|| { [ ! "$buildDate" -nt "$cacheFile" ]; } \
				; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
					cat "$cacheFile"
					return 0
				fi
			fi
	
			if [ ! -f "$MDSC_SOURCE/$projectName/project.inf" ]; then
				echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
				set +e ; return 1
			fi

			echo "$MDSC_CMD: $projectName: caching project index ($MDSC_OPTION)" >&2

			mkdir -p "${cacheFile%/*}"
			DistroSystemContext --project-index-declares "$projectName" \
			tee "$cacheFile.$$.tmp"
			mv -f -- "$cacheFile.$$.tmp" "$cacheFile"

			return 0
		fi
		
		if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
			local buildDate="$MDSC_CACHED/build-time-stamp.txt"
			local indexFile=

			if [ ! -f "$MDSC_SOURCE/$projectName/project.inf" ]; then
				echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
				set +e ; return 1
			fi
			
			for indexFile in "$projectName/project-index.env.inf" "${projectName%%/*}/repository-index.env.inf" "distro-index.env.inf"; do
				local indexFile="$MDSC_CACHED/$indexFile"

				[ -f "$indexFile" ] || continue
				if { [ -n "$BUILD_STAMP" ] && [ ! "$BUILD_STAMP" -gt "$( date -u -r "$indexFile" "+%Y%m%d%H%M%S" )" ]; } \
				|| { [ -f "$buildDate" ] && [ ! "$buildDate" -nt "$indexFile" ]; } \
				; then

					echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
					
					awk -v projectName="$projectName" '
						BEGIN { prefix = "PRJ-DCL-" projectName "=" }
						index($0, prefix)==1 {
							rhs = substr($0, length(prefix)+1)
							gsub(/\\:/, ":", rhs)
							n = split(rhs, a, /[[:space:]]+/)
							for (i=1;i<=n;i++) if (a[i]!="") print projectName, a[i]
						}
					' "$indexFile"

					return 0
				fi
			done
		fi
	fi
	
	if [ javac = "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ "$MDSC_INMODE" = "source" ] ; then
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2
		(
			Distro DistroSourceCommand \
				-q \
				--import-from-source \
				--select-project "$projectName" \
				--print-declares-separate-lines
		)
		return 0
	fi
	
	if [ ! -f "$MDSC_SOURCE/$projectName/project.inf" ]; then
		echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
		set +e ; return 1
	fi

	DistroSystemContext --project-index-declares "$projectName" "${1:-cat}" "${@:2}"
	return 0
}

case "$0" in
	*/sh-scripts/ListProjectDeclares.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectDeclares.fn.sh <project_name> [--print-project] [--print-declares-only] [--merge-sequence] [--filter-and-cut filter_by]" >&2
			echo "📘 syntax: ListProjectDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Options:" >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "  Examples:" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-declares-only --filter-and-cut deploy-export" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-declares-only --filter-and-cut deploy-export --merge-sequence" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project " >&2
			fi
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectDeclares "$@"
	;;
esac
