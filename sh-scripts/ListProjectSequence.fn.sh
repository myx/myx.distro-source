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

	case $1 in
		--help|--help-syntax)
			echo "📘 syntax: ListProjectSequence.fn.sh [--no-cache] <project_name> [--print-project] [--print-{provides|declares|keywords}]" >&2
			echo "📘 syntax: ListProjectSequence.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListProjectSequence.include" >&2
			fi
			return 0
		;;
	esac

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	local MDSC_LP=

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--print-project)
				shift
				MDSC_LP="$projectName "
				continue
			;;
			--print-declares|--print-keywords|--print-provides)
				[ -z "$2" ] || {
					echo "⛔ ERROR: $MDSC_CMD: $1, no extra options allowed:" "$@" >&2
					set +e ; return 1
				}
				local idx="${1#'--print-'}"; shift
				DistroSystemContext --index-${idx}-merged awk -v prj="$projectName" -v lp="$MDSC_LP" '
					$1 == prj && !x[$3]++ { print lp $2, $3; }
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
	awk -v lp="$MDSC_LP" '!x[$2] { print lp $2; }'

}

case "$0" in
	*/sh-scripts/ListProjectSequence.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			ListProjectSequence ${1:-"--help-syntax"}
			exit 1
		fi

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectSequence "$@"
	;;
esac
