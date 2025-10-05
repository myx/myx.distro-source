#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListDistroDeclares(){
	local MDSC_CMD='ListDistroDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	set -e
	
	while true ; do
		case "$1" in
			--all-*|--add-*-column)
				break
			;;
			--explicit-noop)
				shift
				break
			;;
			--select-from-env)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
					set +e ; return 1
				fi
				break
			;;
			--set-env)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --set-env argument expected!" >&2
					set +e ; return 1
				fi
				local envName="$1" ; shift
				eval "$envName='` $MDSC_CMD --explicit-noop "$@" `'"
				return 0
			;;
			--*)
				Distro ListDistroProjects --select-execute-default ListDistroDeclares "$@"
				return 0
			;;
			*)
				break
			;;
		esac
	done

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllDeclares=""
	local indexOwnDeclares=""
	local indexColumns=""

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--all-declares)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-declares cat
				return 0
			;;
			--all-declares-merged)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-declares-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-declares-merged cat
				return 0
			;;
			--add-own-declares-column|--filter-own-declares-column|--add-merged-declares-column|--filter-merged-declares-column)
				local lastOperation=${1%"-declares-column"} ; shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local columnMatcher="$1" ; shift
				if [ "--add-own" = "$lastOperation" ] || [ "--filter-own" = "$lastOperation" ] ; then
					if [ -z "${indexOwnDeclares:0:1}" ] ; then
						local indexOwnDeclares="$( 
							DistroSystemContext --index-declares cat
						)"
					fi
				else
					if [ -z "${indexAllDeclares:0:1}" ] ; then
						local indexAllDeclares="$( 
							DistroSystemContext --index-declares-merged cat
						)"
					fi
				fi
				
				
				local indexCurrent="` \
					if [ -z "${indexColumns:0:1}" ] ; then
						if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
							if [ "--add-own" = "lastOperation" ] || [ "--filter-own" = "lastOperation" ] ; then
								echo "$indexOwnDeclares" | cut -d" " -f1
							else
								echo "$indexAllDeclares" | awk '$1 && !seen[$1]++ { print $1; }'
							fi
						else
							echo "$MDSC_SELECT_PROJECTS"
						fi
					else
						echo "$indexColumns"
					fi \
					| cat -n \
					| sort -k 2 \
				`"
				
				local indexFiltered="` \
					case "$columnMatcher:$lastOperation" in
						*::--add-own|*::--filter-own)
							echo "$indexOwnDeclares" | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-own|*:--filter-own)
							echo "$indexOwnDeclares" | grep -e "^\S* $columnMatcher$"
						;;
						*::--add-merged|*::--filter-merged)
							echo "$indexAllDeclares" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-merged|*:--filter-merged)
							echo "$indexAllDeclares" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher$"
						;;
					esac \
					| awk '$0 && !x[$0]++' \
					| cat -n \
					| sort -k 2 \
				`"

				local tmpKey tmpInt1 tmpColumn tmpInt2 tmpColumns
				local indexColumns="` \
					case "$lastOperation" in
						--add-own|--add-merged)
							# join -e '-' -a 2 -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" )
							local indexVirtual="$( \
								( \
									echo "$indexFiltered" | tr '\t' ' ' | sed -E -e 's|^[ ]+||' ; \
									join -v 2 -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" ) | sed -e 's|$| -|' \
								) \
								| sort -k 2 \
							)"
							join -12 -22 <( echo "$indexVirtual" ) <( echo "$indexCurrent" )
						;;
						--filter-own|--filter-merged)
							join -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" )
						;;
					esac \
					| sort -n -k 2,4 \
					| while read -r tmpKey tmpInt1 tmpColumn tmpInt2 tmpColumns ; do
						# | cut -d" " -f 1,5-,3
						echo $tmpKey $tmpColumns $tmpColumn
					done \
					| awk '$0 && !x[$0]++' \
				`"
				
				if [ -z "$indexColumns" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation no projects selected!" >&2
					set +e ; return 1
				fi
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" projectName projectDeclares ; shift
				DistroSystemContext --index-declares cat \
				| while read -r projectName projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --merge-sequence, no projects selected!" >&2
					set +e ; return 1
				fi
				
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX "$sequenceProjectName" --merge-sequence "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			'')
				if [ -n "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					DistroSystemContext --index-declares \
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b] $0}' \
						<( echo "$MDSC_SELECT_PROJECTS" )
					return 0
				fi

				echo "⛔ ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

}

case "$0" in
	*/sh-scripts/ListDistroDeclares.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListDistroDeclares.fn.sh [<options>] --all-declares" >&2
			# echo "📘 syntax: ListDistroDeclares.fn.sh [<options>] --all-declares-merged" >&2
			echo "📘 syntax: ListDistroDeclares.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "📘 syntax: ListDistroDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListDistroDeclares.include"
			fi
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListDistroDeclares "$@"
	;;
esac
