#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi


ListProjectBuilders(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ListSourceProjectProvides: 'projectName' argument is required!" >&2 ; return 1
	fi
	local stageType="$2"
	if [ -z "$stageType" ] ; then
		echo "ListSourceProjectProvides: 'stageType' argument is required!" >&2 ; return 1
	fi
	local buildersPath="$MMDAPP/source/$projectName/$stageType/builders"
	[ -d "$buildersPath" ] || return 0
	### only 1xxx - source-prepare, source-to-cached by default
	local stageFilter="${3#--}"
	for LINE in $( \
			find "$buildersPath" -mindepth 1 -type f -name $( \
					[ -z "$stageFilter" ] && echo "????-*.sh" || echo "$stageFilter???-*.sh" \
			) | sort \
		) ; do
		echo "${LINE#$MMDAPP/source/}"
	done
}

case "$0" in
	*/sh-scripts/ListProjectBuilders.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectBuilders.fn.sh <project> <source-prepare|source-process|image-prepare|image-share|image-deploy>" >&2
			echo "syntax: ListProjectBuilders.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListProjectBuilders.fn.sh --distro-from-source myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "	ListProjectBuilders.fn.sh --distro-source-only myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "	ListProjectBuilders.fn.sh --distro-from-cached myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "	ListProjectBuilders.fn.sh myx/myx.distro-source source-prepare" >&2
				echo "	ListProjectBuilders.fn.sh myx/myx.distro-source source-process" >&2
				echo "	ListProjectBuilders.fn.sh myx/myx.distro-source image-prepare" >&2
			fi
			exit 1
		fi
		
		ListProjectBuilders "$@"
	;;
esac