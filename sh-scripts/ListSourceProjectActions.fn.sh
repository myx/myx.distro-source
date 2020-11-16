#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


ListSourceProjectActions(){
	local ACT_PATH="$MMDAPP/source/${1#$MMDAPP/source/}/actions"
	[ -d "$ACT_PATH" ] || return 0
	for LINE in `find "$ACT_PATH" -mindepth 1 -type f | sort` ; do
		echo "${LINE#$MMDAPP/source/}"
	done
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