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
			--print-no-project|--print-declares-only)
				shift
				ListProjectDeclares "$projectName" "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift; [ -n "$1" ] || break
				ListProjectDeclares "$projectName" "$@" # | sed "s|^|$projectName |g"
				return 0
			;;
			--filter-and-cut)
				if [ -z "$2" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filter="$2" output ; shift 2

				if [ -z "$1" ] ; then
					DistroSystemContext --project-index-declares "$projectName" \
					awk -v filter="${filter%:}" '
						BEGIN { pref = filter ":"; plen = length(pref) }
						substr($2, 1, plen) == pref && !seen[$0]++ { print $1 " " substr($2, plen + 1) }
					'
					return 0
				fi

				ListProjectDeclares "$projectName" --print-no-project "$@" \
				| while read -r output ; do
				 	if [ "$output" != "${output#${filter}:}" ] ; then
						echo "$projectName ${output#${filter}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift

				if [ -z "$1" ] ; then
					DistroSystemContext --project-index-declares-merged "$projectName" \
					awk '
						{
							out = $2 " " $3
							if (!seen[out]++) { print out }
						}
					'
					return 0
				fi

				local sequenceProjectName
				Distro ListProjectSequence "$projectName" \
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
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListProjectDeclares.include"
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectDeclares "$@"
	;;
esac
