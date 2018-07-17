#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


type ListAllProjects >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListAllProjects.fn.sh"
	
type ListSourceProjectActions >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListSourceProjectActions.fn.sh"
	
ListSourceActions(){
	for PKG in $( ListAllProjects ) ; do
		ListSourceProjectActions "$PKG"
	done	
}

case "$0" in
	*/sh-scripts/ListSourceActions.fn.sh) 
		ListSourceActions
	;;
esac