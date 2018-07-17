#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListPublicFolders(){
	[ -z "$1" ] && echo "ListPublicFolders: path is required!" && exit 1
	find "$1" -mindepth 1 -maxdepth 1 -type d | sort
}

case "$0" in
	*/sh-scripts/ListPublicFolders.fn.sh) 
		ListPublicFolders "$@"
	;;
esac