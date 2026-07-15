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

ListProjectDependants(){
	case "$1" in
		--help|--help-syntax)
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListProjectDependants.include"
			return 0
		;;
	esac

	local MDSC_CMD='ListProjectDependants'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	local MDSC_LP=

	while true ; do
		case "$1" in
			--print-project)
				shift
				MDSC_LP="$projectName "
				continue
			;;
			--line-prefix)
				if [ -z "$2" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $1: prefix value is expected!" >&2
					set +e ; return 1
				fi
				MDSC_LP="$2"; shift 2
				continue
			;;
			'')
				break
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	# distro-wide sequence index holds "<project> <transitively-required-project>" pairs
	# (built from Requires/Provides); a dependant of $projectName is any project whose
	# pair's second column is $projectName - i.e. this is that column's inverse.
	DistroSystemContext --index-sequence awk -v prj="$projectName" -v lp="$MDSC_LP" '
		$2 == prj && $1 != prj && !seen[$1]++ { print lp $1; }
	'
	return 0
}

case "$0" in
	*/sh-scripts/ListProjectDependants.fn.sh)
		set -e

		# ListProjectDependants.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.example.org
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.example.org
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-r4 2> /dev/null

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			ListProjectDependants "${1:-"--help-syntax"}"
			exit 1
		fi

		ListProjectDependants "$@"
	;;
esac
