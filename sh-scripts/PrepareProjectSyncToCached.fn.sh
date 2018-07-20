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

PrepareProjectSyncToCached(){
	set -e
	
	local projectName="${1#$MMDAPP/source/}"
	if [ -z "$projectName" ] ; then
		echo "PrepareProjectSyncToCached: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local projectSrc="$MMDAPP/source/$projectName"

	local projectDst="$MMDAPP/cached/sources/$projectName"
	mkdir -p "$projectDst"

	local projectChg="$MMDAPP/cached/changed/$projectName"
	if [ -f "$projectChg" ] ; then
		echo "already marked as changed." 
	fi
	
	if local ROUTPUT="`rsync -a -i --delete --exclude '.*' --exclude 'CVS' "$projectSrc/" "$projectDst"`" ; then
		if [ -z "$ROUTPUT" ] ; then
			echo "not changed on this run."
		else
			echo "$ROUTPUT"
			mkdir -p "`dirname "$projectChg"`"
			touch "$projectChg"
			echo "changed."
			
			#### looking for embedded packages
			local embeddedPath="$projectDst/source-projects"
			if [ -d "$embeddedPath" ] ; then
				local embeddedList="`find "$embeddedPath" -mindepth 3 -maxdepth 3 -type f -name project.inf | sort | sed 's|/project.inf$||g' | sed "s|^$embeddedPath/||g"`"
				if [ ! -z "$embeddedList" ] ; then
					for embeddedName in $embeddedList ; do
						local embeddedSrc="$embeddedPath/$embeddedName"
					
						local embeddedDst="$MMDAPP/cached/sources/$embeddedName"
						mkdir -p "$embeddedDst"
					
						local embeddedChg="$MMDAPP/cached/changed/$embeddedName"
						if [ -f "$embeddedChg" ] ; then
							echo "$embeddedName: already marked as changed." 
						fi
						
						if local EOUTPUT="`rsync -a -i --delete --exclude '.*' --exclude 'CVS' "$embeddedSrc/" "$embeddedDst"`" ; then
							if [ -z "$EOUTPUT" ] ; then
								echo "$embeddedName: not changed on this run."
							else
								echo "$EOUTPUT"
								mkdir -p "`dirname "$embeddedChg"`"
								touch "$embeddedChg"
								echo "$embeddedName: changed."
							fi
						else
							echo "ERROR: $embeddedName: $EOUTPUT" >&2 ; return 1
						fi
					done
				fi
			fi
			
		fi
	else
		echo "ERROR: $ROUTPUT" >&2 ; return 1
	fi
}

case "$0" in
	*/sh-scripts/PrepareProjectSyncToCached.fn.sh) 
		PrepareProjectSyncToCached "$@"
	;;
esac