#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListDistroKeywords(){
	local MDSC_CMD='ListDistroKeywords'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	set -e

	while true ; do
		case "$1" in
			--all-*|--add-*-column|--filter-and-cut)
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
				Distro ListDistroProjects --select-execute-default ListDistroKeywords "$@"
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
			--all-keywords)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-keywords option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-keywords cat
				return 0
			;;
			--all-keywords-merged)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-keywords-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroSystemContext --index-keywords-merged cat
				return 0
			;;
			--add-own-keywords-column|--filter-own-keywords-column|--add-merged-keywords-column|--filter-merged-keywords-column)
				local columnOp=${1%"-keywords-column"} ; shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $columnOp project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local columnMatch="$1" ; shift
				local indexCurrent indexFiltered indexColumns

				# currently selected projects, 1 column, or iterative ++ columns
				indexCurrent="$(
					[ -z "${indexColumns:0:1}" ] || { echo "$indexColumns"; return 0; }
					[ -z "${MDSC_SELECT_PROJECTS:0:1}" ] || { echo "$MDSC_SELECT_PROJECTS"; return 0; }
					DistroSystemContext --index-projects cat
				)"

				indexFiltered="`
					case "${columnMatch}:${columnOp}" in
						*::--add-own|*::--filter-own)
							DistroSystemContext --index-keywords \
							awk -v m="$columnMatch" 'index($2,m)==1 { ro=$1 " " substr($2,length(m)+1); if (!x[ro]++) print ro; }'
						;;
						*::--add-merged|*::--filter-merged)
							DistroSystemContext --index-keywords-merged \
							awk -v m="$columnMatch" 'index($3,m)==1 { rm=$1 " " substr($3,length(m)+1); if (!x[rm]++) print rm; }'
						;;
						*:--add-own|*:--filter-own)
							DistroSystemContext --index-keywords \
							awk -v m="$columnMatch" '$2==m && !x[$0]++ { print; }'
						;;
						*:--add-merged|*:--filter-merged)
							DistroSystemContext --index-keywords-merged \
							awk -v m="$columnMatch" '$3==m { r= $1 " " $3; if (!x[r]++) print r; }'
						;;
					esac
				`"

				case "$columnOp" in
					--add-own|--add-merged)
						indexFiltered="$(
							awk '
								NR==FNR {
									{ print $1, $2; map[$1]=1 }
									next
								}
								!($1 in map) && !map[$1]++ { print $1, "-" }
							' \
							<(printf "%s\n" "$indexFiltered") \
							<(printf "%s\n" "$indexCurrent")
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
					echo "⛔ ERROR: $MDSC_CMD: ${columnOp}-keywords-column $columnMatch no projects selected!" >&2
					set +e ; return 1
				fi

				continue
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local filterKeywords="$1" indexSpec=; shift
				[ -z "${MDSC_SELECT_PROJECTS:0:1}" ] || indexSpec='--select-index'
				DistroSystemContext ${indexSpec:-'--index'}-keywords awk -v f="${filterKeywords}:" '
				{
					if (index($2, f) == 1) {
						out = $1 " " substr($2, length(f) + 1)
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
				
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectKeywords $MDSC_NO_CACHE $MDSC_NO_INDEX "$sequenceProjectName" --merge-sequence "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			'')
				if [ -n "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					DistroSystemContext --index-keywords \
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
	*/sh-scripts/ListDistroKeywords.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListDistroKeywords.fn.sh --all-keywords" >&2
			echo "📘 syntax: ListDistroKeywords.fn.sh --all-keywords-merged" >&2
			echo "📘 syntax: ListDistroKeywords.fn.sh <project-selector> [--merge-sequence]" >&2
			echo "📘 syntax: ListDistroKeywords.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.ListDistroKeywords.include"
			fi
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListDistroKeywords "$@"
	;;
esac
