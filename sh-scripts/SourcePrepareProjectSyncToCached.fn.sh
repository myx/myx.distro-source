#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! command -v rsync >/dev/null ; then
	echo "⛔ ERROR: $0: rsync utility is required!" >&2
	exit 1
fi

SourcePrepareProjectSyncToCached(){
	set -e

	local MDSC_CMD='SourcePrepareProjectSyncToCached'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	local projectName="${1#$MMDAPP/source/}"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi
	
	local projectSrc="$MMDAPP/source/$projectName"

	local projectDst="$MMDAPP/cached/sources/$projectName"
	mkdir -p "$projectDst"

	local projectChg="$MMDAPP/cached/changed/$projectName"
	if [ -f "$projectChg" ] ; then
		echo "already marked as changed." >&2 
	fi


	local ROUTPUT

	# rlpgoDitO
	if ROUTPUT="$( 

		rsync -aiO --delete --delete-excluded \
			--exclude='.DS_Store' \
			--exclude='Icon?' \
			--exclude='._*' \
			--exclude='.Spotlight-V100' \
			--exclude='.Trashes' \
			--exclude='.*' \
			--exclude='CVS' \
			"$projectSrc/" "$projectDst" \
		2>&1

	)" ; then
		if [ -z "$ROUTPUT" ] ; then
			echo "not changed on this run." >&2
		else
			echo "$ROUTPUT" >&2

			mkdir -p "$( dirname "$projectChg" )"
			touch "$projectChg"
			echo "changed." >&2
			
			#### looking for embedded packages
			local embeddedPath="$projectDst/source-projects"
			if [ -d "$embeddedPath" ] ; then
				local embeddedList="`find "$embeddedPath" -mindepth 3 -maxdepth 3 -type f -name project.inf | sort | sed 's|/project.inf$||g' | sed "s|^$embeddedPath/||g"`"
				if [ -n "$embeddedList" ] ; then
					for embeddedName in $embeddedList ; do
						local embeddedSrc="$embeddedPath/$embeddedName"
					
						local embeddedDst="$MMDAPP/cached/sources/$embeddedName"
						mkdir -p "$embeddedDst"
					
						local embeddedChg="$MMDAPP/cached/changed/$embeddedName"
						if [ -f "$embeddedChg" ] ; then
							echo "$embeddedName: already marked as changed."  >&2
						fi
						
						local EOUTPUT
						if EOUTPUT="$( 

							rsync -rlpgoDitO --delete \
								--exclude '.*' \
								--exclude 'CVS' \
								"$embeddedSrc/" \
								"$embeddedDst" \
							2>&1 \
							| (grep --line-buffered -e '^>f' -e '^cd' -e '^\*' || :)
							
						)" ; then
							if [ -z "$EOUTPUT" ] ; then
								echo "$embeddedName: not changed on this run." >&2
							else
								echo "$EOUTPUT" >&2
								mkdir -p "$( dirname "$embeddedChg" )"
								touch "$embeddedChg"
								echo "$embeddedName: changed." >&2
							fi
						else
							echo "⛔ ERROR: $embeddedName: $EOUTPUT" >&2
							set +e ; return 1
						fi
					done
				fi
			fi
			
		fi
	else
		echo "⛔ ERROR: $ROUTPUT" >&2
		set +e ; return 1
	fi
}

case "$0" in
	*/sh-scripts/SourcePrepareProjectSyncToCached.fn.sh) 
		SourcePrepareProjectSyncToCached "$@"
	;;
esac
