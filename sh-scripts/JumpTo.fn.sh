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

if ! type DistroImage >/dev/null 2>&1 ; then
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"
fi

JumpTo(){

	set -e

	local MDSC_CMD='JumpTo'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local baseDirectory="$MDSC_SOURCE"

	while true ; do
		case "$1" in
			--cd-source)
				shift
			;;
			--cd-output)
				local baseDirectory="$MDSC_OUTPUT" ; shift
			;;
			--cd-cached)
				local baseDirectory="$MDSC_CACHED" ; shift
			;;
			--cd-*)
				echo "$MDSC_CMD: ⛔ ERROR: invalid --cd-XXXX option: $1" >&2
				set +e ; return 1
			;;
			*)
				break
			;;
		esac
	done

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo -e "$MDSC_CMD: ⛔ ERROR: 'filterProject' argument (name or keyword or substring) is required!" >&2
		set +e ; return 1
	fi

	shift

	Require ListDistroProjects

	local targetProject
	targetProject="$( ListDistroProjects --one-project "$filterProject" )"

	printf "Target: \n    %s\n" "$targetProject" >&2
	
	declare -x MDSC_INT_CD="$baseDirectory/$targetProject"
	MDSC_INT_CD="$baseDirectory/$targetProject"
	export MDSC_INT_CD
	PWD="$baseDirectory/$targetProject"
	export PWD
	cd "$baseDirectory/$targetProject"
}

case "$0" in
	*/sh-scripts/JumpTo.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: JumpTo.fn.sh <project> [<ssh arguments>...]" >&2
			echo "📘 syntax: JumpTo.fn.sh <unique-project-name-part> [<ssh arguments>...]" >&2
			echo "📘 syntax: JumpTo.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    JumpTo.fn.sh ndss113" >&2
				echo "    JumpTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
			fi
			exit 1
		fi
		
		JumpTo "$@"
	;;
esac
