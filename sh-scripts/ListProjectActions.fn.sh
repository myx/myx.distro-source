#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectActions(){

	local MDSC_CMD='ListProjectActions'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
		. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-path-auto
	fi

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
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi

	local findLocation sedEx
	
	if [ -d "$MDSC_SOURCE/$projectName/actions" ]; then
		findLocation="$MDSC_SOURCE/$projectName/actions"
	elif [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -d "$MMDAPP/source/$projectName/actions" ]; then
		findLocation="$MMDAPP/source/$projectName/actions"
	fi

	if [ -z "${findLocation:0:1}" ] ; then
		return 0
	fi

	if [ -n "$forCompletion" ] ; then
		local sedEx="s:^$findLocation/::g"
	else
		local sedEx="s:^${findLocation%$projectName/actions}::g"
	fi
	
	[ full != "$MDSC_DETAIL" ] || echo "- $MDSC_CMD: will search at '$findLocation'" >&2
	find "$findLocation" -mindepth 1 -type f -not -name '.*' | sed -e "$sedEx" | sort -u
	return 0
}

case "$0" in
	*/sh-scripts/ListProjectActions.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectActions.fn.sh <project>" >&2
			echo "📘 syntax: ListProjectActions.fn.sh [--help]" >&2
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
