#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "`which rsync`" ] ; then
	echo "$0: rsync is required!" >&2
	exit 1
fi

type Async >/dev/null 2>&1 || \
	. "`myx.common which lib/async`"

SyncSourceProjectToCached(){
	local PKG="${1#$MMDAPP/source/}"
	if [ -z "$PKG" ] ; then
		echo "SyncSourceProjectToCached: 'PKG' argument is required!" >&2 ; exit 1
	fi
	
	local SRC="$MMDAPP/source/$PKG"

	local DST="$MMDAPP/cached/sources/$PKG"
	mkdir -p "$DST"

	local CHG="$MMDAPP/cached/changed/$PKG"
	if [ -f "$CHG" ] ; then
		echo "already marked as changed." 
	fi
	
	if local ROUTPUT="`rsync -a -i --delete --exclude '.*' --exclude 'CVS' "$SRC/" "$DST"`" ; then
		if [ -z "$ROUTPUT" ] ; then
			echo "not changed on this run."
		else
			echo "$ROUTPUT"
			mkdir -p "`dirname "$CHG"`"
			touch "$CHG"
			echo "changed."
		fi
	else
		echo "ERROR: $ROUTPUT"
	fi
}

case "$0" in
	*/sh-scripts/SyncSourceProjectToCached.fn.sh) 
		SyncSourceProjectToCached "$@"
	;;
esac