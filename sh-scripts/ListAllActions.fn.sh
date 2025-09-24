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

ListAllActions(){

	local MDSC_CMD='ListAllActions'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local forCompletion=""
	while true ; do
		case "$1" in
			--completion)
				shift
				local forCompletion="--completion"
			;;
			*)
				break
			;;
		esac
	done

	local sedEx="-e \"s:^$MMDAPP/source/::g\" -e \"s:^$MDSC_SOURCE/::g\""

	local projectName findLocations

	for projectName in $( Distro ListDistroProjects --all-projects ) ; do
		local findLocations=""
		
		[ ! -d "$MDSC_SOURCE/$projectName/actions" ] \
		|| local findLocations="$findLocations \"$MDSC_SOURCE/$projectName/actions\""
		
		[ "$MDSC_SOURCE" = "$MMDAPP/source" ] \
		|| [ ! -d "$MMDAPP/source/$projectName/actions" ] \
		|| local findLocations="$findLocations \"$MMDAPP/source/$projectName/actions\""
	
		if [ -z "${findLocations:0:1}" ] ; then
			continue
		fi
		
		if [ -n "$forCompletion" ] ; then
			local sedEx="-e \"s:^$MMDAPP/source/$projectName/actions/::g\" -e \"s:^$MDSC_SOURCE/$projectName/actions/::g\""
		fi
		
		[ "full" != "$MDSC_DETAIL" ] || echo "- $MDSC_CMD: will search at '$findLocations'" >&2
		eval "find $findLocations -mindepth 1 -type f -not -name '.*'" | eval "sed $sedEx"
	done | sort -u
	return 0
	
	
	Require ListProjectActions
	for projectName in $( Distro ListDistroProjects --all-projects ) ; do
		ListProjectActions $forCompletion "$projectName"
	done
		
}

case "$0" in
	*/sh-scripts/ListAllActions.fn.sh) 
		ListAllActions "$@"
	;;
esac
