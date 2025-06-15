#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


if [ -z "$MDLT_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi


ListSourceActions(){
	set +x	
	local MDSC_CMD='ListSourceActions'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2


	Require ListDistroProjects
	# override to source, explicit
	local MDSC_SOURCE="$MMDAPP/source"

	local projectName
	for projectName in $( ListDistroProjects --all-projects ) ; do
		
		[ -d "$MDSC_SOURCE/$projectName/actions" ] && \
			find "$MDSC_SOURCE/$projectName/actions" -mindepth 1 -type f \
			| sed "s:^$MDSC_SOURCE/::g" \
		| sort
		
	done	
}

case "$0" in
	*/sh-scripts/ListSourceActions.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListSourceActions.fn.sh --all [--no-cache]" >&2
			echo "syntax: ListSourceActions.fn.sh --help" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListSourceActions.fn.sh --distro-from-source --all" >&2
				echo "	ListSourceActions.fn.sh --distro-from-cached --all" >&2
				echo "	ListSourceActions.fn.sh --distro-source-only --all" >&2
			fi
			exit 1
		fi

		ListSourceActions "$@"
	;;
esac
