#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProjects
Require ListProjectActions


RebuildActions(){
	if [ -z "$MDSC_SOURCE" ] ; then
		echo "⛔ ERROR: DistroContext is not set!" >&2
		set +e ; return 1
	fi

	local TMP_DIR="$( mktemp -d -t "rebuild-actions-XXXXXXXX" )"
	if [ $? -ne 0 ]; then
		echo "⛔ ERROR: Can't make temporary install directory $TMP_DIR, exiting..." >&2
		set +e ; return 1
	fi
	echo "Using temporary install directory: $TMP_DIR"

	local projectName
	local actionFullName
	local actionLocation
	local actionSourceFile

	if [ "$1" == "--test1" ] ; then
		cd "$MDSC_SOURCE"
		find $( ListDistroProjects --all-projects | tr '\n' ' ' ) -type d -name "actions" -prune
		exit 0
	fi
	if [ "$1" == "--test2" ] ; then
		cd "$MDSC_SOURCE"
		find . -type d -name "actions" -exec sh -c 'test -f "$0/../project.inf" && echo "$0"' {} \; -prune
		exit 0
	fi
	if [ "$1" == "--test3" ] ; then
		ListDistroProjects --select-projects-with-path "-d" "actions"
		exit 0
	fi
	
	for projectName in $( ListDistroProjects --all-projects ) ; do
		
		for actionFullName in $( ListProjectActions "$projectName" ) ; do
			
			actionLocation="$TMP_DIR/${actionFullName#$projectName/actions/}"
			
			if [ -f "$MDSC_SOURCE/$actionFullName" ] ; then
				if [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -f "$MMDAPP/source/$actionFullName" ] ; then
					actionSourceFile="$MMDAPP/source/$actionFullName"
				else
					actionSourceFile="$MDSC_SOURCE/$actionFullName"
				fi
			else
				actionSourceFile="$MMDAPP/source/$actionFullName"
			fi
			
			printf "Processing: %s \n \t \t \t <= %s\n" "${actionLocation#$TMP_DIR/}" "${actionFullName}" >&2

			mkdir -p "$( dirname "$actionLocation" )"

			case "$actionFullName" in
		        *.sh)
					## source code of script being created:
					if true ; then
						echo '#/bin/sh'
						
						echo 'ActionExecutionWrap(){'
						echo 	"local actionScript='${actionFullName#"$projectName/actions/"}'"
						echo 	"local actionFullName='$actionFullName'"
						echo 	'[ "full" != "$MDSC_DETAIL" ] || set -x'
						
						echo 	'if [ -n "$MMDAPP" ] ; then'
						echo 		'[ -z "$MDSC_DETAIL" ] || echo "> Action $actionFullName: using context settings: $MMDAPP" >&2'
						echo 	'elif [ "$0" != "${0%"/source/$actionFullName"}" ] ; then'
						echo 		'export MMDAPP="${0%"/source/$actionFullName"}"'
						echo 		'[ -z "$MDSC_DETAIL" ] || echo "> Action $actionFullName: calculated settings from source: $MMDAPP" >&2'
						echo 	'elif [ "$0" != "${0%"/actions/$actionScript"}" ] ; then'
						echo 		'export MMDAPP="${0%"/actions/$actionScript"}"'
						echo 		'[ -z "$MDSC_DETAIL" ] || echo "> Action $actionFullName: calculated settings from action: $MMDAPP" >&2'
						echo 	'else'
						echo 		'echo "! Action $actionFullName: ⛔ ERROR: cant calculate distro root directory!" >&2'
						echo		'set +e ; return 1'
						echo 	'fi'
						
						echo 	'if [ ! -d "$MMDAPP/source" ] ; then'
						echo 		'echo "! Action $actionFullName: ⛔ ERROR: source directory does not exist!" >&2'
						echo		'set +e ; return 1'
						echo 	'fi'
						
						echo 	'. "$MMDAPP/source/$actionFullName"' 
						echo '}'
						
						echo 'ActionExecutionWrap "$@"'
					fi > "$actionLocation"
					chmod ug=rx,o=r "$actionLocation" 
					;;
		        *.url)
		        	# ( grep -q '\[InternetShortcut\]' "$actionSourceFile" ) && echo "GREP=EYS"
		        	# [ "`wc -l < "$actionSourceFile"`" -gt 1 ] && echo "WCS"
		        	# echo "$actionSourceFile: `wc -l < "$actionSourceFile"`"
					if ( grep -q '\[InternetShortcut\]' "$actionSourceFile" ) || [ "`wc -l < "$actionSourceFile"`" -gt 1 ] ; then
						## sym-link is being created:
						ln -fsv "$actionSourceFile" "$actionLocation"
						chmod -h ug=rx,o=r "$actionLocation" 
					else
			        	local SRCCODE="`cat "$actionSourceFile"`"
			        	local WRKPATH
			        	if [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -f "$MMDAPP/source/$projectName/$SRCCODE" ] ; then
			        		local SRCCODE="file://$MMDAPP/source/$projectName/$SRCCODE"
				        	local WRKPATH="$MMDAPP/source/$projectName"
			        	else
				        	local SRCCODE="file://$MDSC_SOURCE/$projectName/$SRCCODE"
				        	local WRKPATH="$MDSC_SOURCE/$projectName"
			        	fi

						## source code of script being created:
						( echo "[InternetShortcut]" ; echo "URL=$SRCCODE" ; echo "WorkingDirectory=$WRKPATH" ) > "$actionLocation"
						chmod ug=rx,o=r "$actionLocation" 
					fi 
					;;
		        *)
					## sym-link is being created:
					ln -fsv "$actionSourceFile" "$actionLocation"
					chmod -h ug=rx,o=r "$actionLocation" 
		            ;;
			esac
		done
	done	
	
	rsync -irltoODC $( [ "--no-delete" == "$1" ] || echo "--delete" ) --chmod=ug+rwx "$TMP_DIR/" "$MMDAPP/actions" 2>&1 \
	| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || true)
	rm -rf "$TMP_DIR"
}

case "$0" in
	*/sh-scripts/RebuildActions.fn.sh) 
		RebuildActions "$@"
	;;
esac
