#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

type ListPublicFolders >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListPublicFolders.fn.sh"

CheckEchoSourceProject(){
	local PKG_PATH="$1"
	[ -z "$PKG_PATH" ] && echo '$PKG_PATH' is not set! >&2 && exit 1
	[ ! -d "$PKG_PATH" ] && return 0

	local NOT_DEEP="$2"
	
	[ -f "$PKG_PATH/project.inf" ] && echo "$PKG_PATH" && return 0
	
	[ -d "$PKG_PATH/ae3-packages" ] && echo "$PKG_PATH" && return 0
	
	if [ -z "$NOT_DEEP" ] ; then
		for CHK_PATH in `ListPublicFolders "$PKG_PATH"` ; do
			CheckEchoSourceProject "$CHK_PATH" "TRUE"
		done	
	fi
}

case "$0" in
	*/sh-scripts/CheckEchoSourceProject.fn.sh) 
		CheckEchoSourceProject "$@"
	;;
esac