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


ListSourceProjectProvides(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ListSourceProjectProvides: 'projectName' argument is required!" >&2 ; return 1
	fi

	Require DistroSourceCommand
	DistroSourceCommand \
		--import-from-source \
		--select-project "$projectName" \
		--print-provides --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectProvides.fn.sh)
		# ListSourceProjectProvides.fn.sh "myx/clean-boot"
	 

		# . "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		# DistroShellContext --distro-from-source
		
		ListSourceProjectProvides "$@"
	;;
esac