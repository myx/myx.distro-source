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


ListSourceProjectRequires(){

	local MDSC_CMD='ListSourceProjectRequires'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi

	shift
	set -e

	Require DistroSourceCommand
	DistroSourceCommand \
		--import-from-source \
		--select-project "$projectName" \
		--print-requires --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectRequires.fn.sh)
		# ListSourceProjectRequires.fn.sh "myx/clean-boot"
	 

		# . "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		# DistroShellContext --distro-from-source
		
		ListSourceProjectRequires "$@"
	;;
esac
