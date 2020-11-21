#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

Require ListDistroProjects
Require ListProjectBuilders

ListDistroBuilders(){
	local stageType="$1"
	if [ -z "$1" ] ; then
		echo "ListDistroBuilders: 'stageType' argument is required!" >&2 ; return 1
	fi
	local projectName
	for projectName in ` ListDistroProjects --all-projects ` ; do
		ListProjectBuilders "$projectName" "$@"
	done
}

case "$0" in
	*/sh-scripts/ListDistroBuilders.fn.sh) 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroBuilders.fn.sh <source-prepare|source-process|image-prepare|image-share|image-deploy>" >&2
			echo "syntax: ListDistroBuilders.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListDistroBuilders.fn.sh --distro-from-source source-prepare 2> /dev/null | sort" >&2
				echo "    ListDistroBuilders.fn.sh --distro-from-cached source-prepare | sort" >&2
				echo "    ListDistroBuilders.fn.sh --distro-source-only source-prepare | sort" >&2
				echo "    ListDistroBuilders.fn.sh source-prepare" >&2
				echo "    ListDistroBuilders.fn.sh source-process" >&2
				echo "    ListDistroBuilders.fn.sh image-prepare" >&2
				echo "    ListDistroBuilders.fn.sh image-share" >&2
				echo "    ListDistroBuilders.fn.sh image-deploy" >&2
			fi
			exit 1
		fi
		
		ListDistroBuilders "$@"
	;;
esac