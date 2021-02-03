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

	local MDSC_CMD='ListProjectActions'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"
	local forCompletion=""
	while true ; do
		case "$1" in
			--completion)
				shift
				local forCompletion="true"
			;;
			*)
				break
			;;
		esac
	done

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		return 1
	fi

	local findLocations=""
	
	[ ! -d "$MDSC_SOURCE/$projectName/actions" ] \
	|| local findLocations="$findLocations \"$MDSC_SOURCE/$projectName/actions\""
	
	[ "$MDSC_SOURCE" = "$MMDAPP/source" ] \
	|| [ ! -d "$MMDAPP/source/$projectName/actions" ] \
	|| local findLocations="$findLocations \"$MMDAPP/source/$projectName/actions\""

	if [ -z "${findLocations:0:1}" ] ; then
		return 0
	fi
	
	if [ ! -z "$forCompletion" ] ; then
		local sedEx="-e \"s:^$MMDAPP/source/$projectName/actions/::g\" -e \"s:^$MDSC_SOURCE/$projectName/actions/::g\""
	else
		local sedEx="-e \"s:^$MMDAPP/source/::g\" -e \"s:^$MDSC_SOURCE/::g\""
	fi
	
	[ "full" != "$MDSC_DETAIL" ] || echo "- $MDSC_CMD: will search at '$findLocations'" >&2
	eval "find $findLocations -mindepth 1 -type f -not -name '.*'" | eval sed $sedEx | sort -u
	return 0
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