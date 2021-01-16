#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi


ListSourceActions(){
	Require ListDistroProjects
	Require ListSourceProjectActions
	
	local PKG
	for PKG in ` ListDistroProjects --all-projects ` ; do
		ListSourceProjectActions "$PKG"
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