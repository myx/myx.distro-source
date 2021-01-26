#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


ListSourceProjectActions(){

	local MDSC_CMD='ListSourceProjectActions'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	# override to source, explicit
	local MDSC_SOURCE="$MMDAPP/source"

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		return 1
	fi
	
	( \
	[ -d "$MDSC_SOURCE/$projectName/actions" ] && \
		find "$MDSC_SOURCE/$projectName/actions" -mindepth 1 -type f \
		| sed "s:^$MDSC_SOURCE/::g" \
	) | sort
	
	return 0
}

case "$0" in
	*/sh-scripts/ListSourceProjectActions.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListSourceProjectActions.fn.sh <project>" >&2
			echo "syntax: ListSourceProjectActions.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListSourceProjectActions.fn.sh myx/myx.distro-source 2> /dev/null" >&2
			fi
			exit 1
		fi
		
		ListSourceProjectActions "$@"
	;;
esac