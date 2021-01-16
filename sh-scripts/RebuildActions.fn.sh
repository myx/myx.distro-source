#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProjects
Require ListProjectActions


RebuildActions(){
	if [ -z "$MDSC_SOURCE" ] ; then
		echo "ERROR: DistroContext is not set!" >&2
		return 1
	fi

	local TMP_DIR="$(mktemp -d -t "rebuild-actions-")"
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't make temporary install directory $TMP_DIR, exiting..." >&2
		return 1
	fi
	echo "Using temporary install directory: $TMP_DIR"

	local projectName
	local ACTION
	local ACTTGT
	local ACTSRC
	
	for projectName in ` ListDistroProjects --all-projects ` ; do
		
		for ACTION in $( ListProjectActions "$projectName" ) ; do
			
			ACTTGT="$TMP_DIR/${ACTION#$projectName/actions/}"
			
			if [ -f "$MDSC_SOURCE/$ACTION" ] ; then
				if [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -f "$MMDAPP/source/$ACTION" ] ; then
					ACTSRC="$MMDAPP/source/$ACTION"
				else
					ACTSRC="$MDSC_SOURCE/$ACTION"
				fi
			else
				ACTSRC="$MMDAPP/source/$ACTION"
			fi
			
			printf "Processing: %s \n \t \t \t <= %s\n" "${ACTTGT#$TMP_DIR/}" "${ACTION}" >&2

			mkdir -p "`dirname "$ACTTGT"`"

			case "$ACTION" in
		        *.sh)
					## source code of script being created:
					( echo "#/bin/sh" ; echo "export MMDAPP='$MMDAPP'" ; echo ". '$ACTSRC'" ) > "$ACTTGT"
					chmod ug=rx,o=r "$ACTTGT" 
					;;
		        *.url)
		        	# ( grep -q '\[InternetShortcut\]' "$ACTSRC" ) && echo "GREP=EYS"
		        	# [ "`wc -l < "$ACTSRC"`" -gt 1 ] && echo "WCS"
		        	# echo "$ACTSRC: `wc -l < "$ACTSRC"`"
					if ( grep -q '\[InternetShortcut\]' "$ACTSRC" ) || [ "`wc -l < "$ACTSRC"`" -gt 1 ] ; then
						## sym-link is being created:
						ln -fsv "$ACTSRC" "$ACTTGT"
						chmod -h ug=rx,o=r "$ACTTGT" 
					else
			        	local SRCCODE="`cat "$ACTSRC"`"
			        	local WRKPATH
			        	if [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -f "$MMDAPP/source/$projectName/$SRCCODE" ] ; then
			        		local SRCCODE="file://$MMDAPP/source/$projectName/$SRCCODE"
				        	local WRKPATH="$MMDAPP/source/$projectName"
			        	else
				        	local SRCCODE="file://$MDSC_SOURCE/$projectName/$SRCCODE"
				        	local WRKPATH="$MDSC_SOURCE/$projectName"
			        	fi

						## source code of script being created:
						( echo "[InternetShortcut]" ; echo "URL=$SRCCODE" ; echo "WorkingDirectory=$WRKPATH" ) > "$ACTTGT"
						chmod ug=rx,o=r "$ACTTGT" 
					fi 
					;;
		        *)
					## sym-link is being created:
					ln -fsv "$ACTSRC" "$ACTTGT"
					chmod -h ug=rx,o=r "$ACTTGT" 
		            ;;
			esac
		done
	done	
	
	rsync -rltoDC `[ "--no-delete" == "$1" ] || echo "--delete"` --chmod=ug+rw --omit-dir-times "$TMP_DIR/" "$MMDAPP/actions"
	rm -rf "$TMP_DIR"
}

case "$0" in
	*/sh-scripts/RebuildActions.fn.sh) 
		RebuildActions "$@"
	;;
esac