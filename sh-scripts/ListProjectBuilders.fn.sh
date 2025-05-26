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


ListProjectBuilders(){

	local MDSC_CMD='ListProjectBuilders'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi

	local stageType="$2"
	if [ -z "$stageType" ] ; then
		echo "ERROR: $MDSC_CMD: 'stageType' argument is required!" >&2
		set +e ; return 1
	fi
	if [ "$stageType" = "--all" ] ; then
		for stageType in source-prepare source-process image-prepare image-process image-install ; do
			ListProjectBuilders "$projectName" "$stageType" "$3"
		done
		return 0
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
			echo "syntax: ListProjectBuilders.fn.sh <project> <source-prepare|source-process|image-prepare|image-process|image-install>" >&2
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