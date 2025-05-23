#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type DistroImage >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"
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
		echo -e "$MDSC_CMD: ⛔ ERROR: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListDistroProjects

	local targets="$( ListDistroProjects --select-projects "$filterProject" )"

	if [ -z "$targets" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2
		set +e ; return 1
	fi
	
	if [ "$targets" != "$( echo "$targets" | head -n 1 )" ] ; then
		echo "$MDSC_CMD: 🙋 STOP: More than one match: $@" >&2
		printf "Targets: \n%s\n" "$( echo "$targets" | sed -e 's|^|   |g' )" >&2
		set +e ; return 2
	fi

	printf "Target: \n    %s\n" "$targets" >&2
	
	declare -x MDSC_INT_CD="$baseDirectory/$targets"
	MDSC_INT_CD="$baseDirectory/$targets"
	export MDSC_INT_CD
	PWD="$baseDirectory/$targets"
	export PWD
	cd "$baseDirectory/$targets"
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
				echo "    JumpTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz -l mysql whoami" >&2
			fi
			exit 1
		fi
		
		JumpTo "$@"
	;;
esac