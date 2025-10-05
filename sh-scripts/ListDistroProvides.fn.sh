#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListDistroProvides(){
	local MDSC_CMD='ListDistroProvides'
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
				Distro ListDistroProjects --select-execute-default ListDistroProvides "$@"
				return 0
			;;
			*)
				break
			;;
		esac
	done

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexColumns=""

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--all-provides)
				shift
				if [ -n "$1" ]; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-provides option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-provides cat
				return 0
			;;
			--all-provides-merged)
				shift
				if [ -n "$1" ]; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-provides-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-merged-provides cat
				return 0
			;;
			--add-own-provides-column|--filter-own-provides-column|--add-merged-provides-column|--filter-merged-provides-column)
				local lastOperation=${1%"-provides-column"}; shift
				if [ -z "$1" ]; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation project provides filter is expected!" >&2
					set +e; return 1
				fi
				local columnMatcher="$1" ; shift
				
				local indexCurrent indexFiltered indexColumns

				# currently selected projects, 1 column, or iterative ++ columns
				indexCurrent="$(
					if [ -z "${indexColumns:0:1}" ]; then
						if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ]; then
							DistroSystemContext --index-projects cat
						else
							echo "$MDSC_SELECT_PROJECTS"
						fi
					else
						echo "$indexColumns"
					fi
				)"

				indexFiltered="`
					case "${columnMatcher}:${lastOperation}" in
						*::--add-own|*::--filter-own)
							DistroSystemContext --index-provides \
							awk -v m="$columnMatcher" 'index($2,m)==1 { ro=$1 " " substr($2,length(m)+1); if (!x[ro]++) print ro; }'
						;;
						*::--add-merged|*::--filter-merged)
							DistroSystemContext --index-merged-provides \
							awk -v m="$columnMatcher" 'index($3,m)==1 { rm=$1 " " substr($3,length(m)+1); if (!x[rm]++) print rm; }'
						;;
						*:--add-own|*:--filter-own)
							DistroSystemContext --index-provides \
							awk -v m="$columnMatcher" '$2==m && !x[$0]++ { print; }'
						;;
						*:--add-merged|*:--filter-merged)
							DistroSystemContext --index-merged-provides \
							awk -v m="$columnMatcher" '$3==m { r= $1 " " $3; if (!x[r]++) print r; }'
						;;
					esac
				`"
				case "$lastOperation" in
					--add-own|--add-merged)
						indexFiltered="$(
							{
								awk '{ gsub(/\t/, " "); sub(/^[ ]+/, ""); print }' \
									<<< "$indexFiltered"
								
								awk '
									NR==FNR { exclude[$2]; next }
									!($2 in exclude) { print $0, "-" }
								' <(echo "$indexFiltered") <(echo "$indexCurrent")
							} \
							| sort -k 2
						)"
					;;
				esac

				indexColumns="`
					awk '
						NR==FNR { key[$1]=$2; next }
						$1 in key {
							out = $0 " " key[$1]
							if (!seen[out]++) print out
						}
					' \
						<(printf "%s\n" "$indexFiltered") \
						<(printf "%s\n" "$indexCurrent")
				`"
				
				if [ -z "$indexColumns" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation no projects selected!" >&2
					set +e ; return 1
				fi

				continue
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project provides filter is expected!" >&2
					set +e ; return 1
				fi
				local filterProvides="$1" projectName projectProvides ; shift

				DistroSystemContext --index-provides cat | awk -v f="$filterProvides" '
				{
					if (index($2, f ":") == 1) {
						out = $1 " " substr($2, length(f) + 2)
						if (!seen[out]++) print out
					}
				}
				'
				return 0
			;;
			--merge-sequence)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --merge-sequence, no projects selected!" >&2
					set +e ; return 1
				fi
				
				Require ListProjectProvides
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectProvides $MDSC_NO_CACHE $MDSC_NO_INDEX "$sequenceProjectName" --merge-sequence "$@" \
					| sed "s|^|$sequenceProjectName |g"
				done \
				| awk '!x[$0]++'
				return 0
			;;
			'')
				if [ -n "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					DistroSystemContext --index-provides \
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
	*/sh-scripts/ListDistroProvides.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListDistroProvides.fn.sh --all-provides" >&2
			echo "📘 syntax: ListDistroProvides.fn.sh --all-provides-merged" >&2
			echo "📘 syntax: ListDistroProvides.fn.sh <project-selector> [--merge-sequence] [<options>]" >&2
			echo "📘 syntax: ListDistroProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListDistroProvides.include"
			fi
			exit 1
		fi

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListDistroProvides "$@"
	;;
esac
