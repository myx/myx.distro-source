#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListProjectActions(){
	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"

	local CUT
	if [ "$1" = "--completion" ] ; then
		shift
		local CUT="${1#$MDSC_SOURCE/}/actions/"
	else
		local CUT=""
	fi

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: ListProjectActions: 'projectName' argument is required!" >&2 ; return 1
	fi
	

	( \
		[ -d "$MDSC_SOURCE/$projectName/actions" ] && \
			( find "$MDSC_SOURCE/$projectName/actions" -mindepth 1 -type f -not -name '.*' | sed "s:^$MDSC_SOURCE/$CUT::g" ) ; \
		[ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -d "$MMDAPP/source/$projectName/actions" ] && \
			( find "$MMDAPP/source/$projectName/actions" -mindepth 1 -type f -not -name '.*' | sed "s:^$MMDAPP/source/$CUT::g" ) \
	) | sort | uniq
}

case "$0" in
	*/sh-scripts/ListProjectActions.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectActions.fn.sh <project>" >&2
			echo "syntax: ListProjectActions.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListProjectActions.fn.sh --distro-from-source myx/myx.distro-source 2> /dev/null" >&2
				echo "	ListProjectActions.fn.sh --distro-source-only myx/myx.distro-source 2> /dev/null" >&2
				echo "	ListProjectActions.fn.sh --distro-from-cached myx/myx.distro-source 2> /dev/null" >&2
			fi
			exit 1
		fi
		
		ListProjectActions "$@"
	;;
esac