#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

type DistroSource >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/lib.distro-source.include"

DistroSourcePrepare(){

	local MDSC_CMD='DistroSourcePrepare'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	set -e

	case "$1" in
		--scan-source-projects)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceProjects.include"
			return 0
		;;
		--scan-source-namespaces)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceNamespaces.include"
			return 0
		;;
		--scan-source-changes)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceChanges.include"
			return 0
		;;
		--sync-cached-from-source) # ...-for-stdin-project-list)
			shift
			[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: syncing to cached ($MDSC_OPTION)" >&2

			local FIFO="$MMDAPP/.local/temp/scan-source-changes-$$.fifo"
			mkfifo "$FIFO"
			exec 3<> "$FIFO"   # fd 3 is now the pipe
			rm "$FIFO"         # no more name on disk, pipe lives on via fd 3

			local projectName

			{
				tee /dev/fd/2 2>&3 # to awk
				echo >&3 # end-of-stream for awk
			} \
			| {
				set -- --execute-sync
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceChanges.include"
			} \
			| if [ -n "$MDSC_DETAIL" ]; then
				if [ "full" = "$MDSC_DETAIL" ]; then
					tee /dev/fd/2
				else
					fgrep -v '>f..t.' \
					| tee /dev/fd/2
				fi
			else
				cat
			fi \
			| cut -d' ' -f2 \
			| awk -v FD=3 '
				BEGIN {
					while (getline proj < ("/dev/fd/" FD)) {
						if (proj == "") break
						projects[proj] = 1
					}
				}
				{
					for (p in projects)
						if (index($0, p"/") == 1)
						changed[p] = 1
				}
				END {
					for (p in changed) print p
				}
			' \
			| sort -u \
			| (
				mkdir -p "$MMDAPP/cached/changed"
				cd "$MMDAPP/cached/changed"
				while IFS= read -r projectName; do
					if [ -f "$projectName" ]; then
						printf '🔂 scan/sync: updated: %s\n' "$projectName" >&2
						continue
					fi
					printf '🔄 scan/sync: changed: %s\n' "$projectName" >&2
					mkdir -p "$( dirname "$projectName" )"					
					touch "$projectName"
				done
			)

			# 4) close fd 3
			exec 3>&-

			return 0
		;;
		--check-ensure-index)
		;;
		--rebuild-source-index)
		;;
		--all-*)
		;;
		--explicit-noop)
			shift
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "⛔ ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
				set +e ; return 1
			fi
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
			Require ListDistroProjects
			ListDistroProjects --select-execute-default DistroSourcePrepare "$@"
			return 0
		;;
	esac

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllJobs=""

	while true ; do
		case "$1" in
			--all-tasks)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
	
				Require ListDistroDeclares
				ListDistroDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX --all-declares-prefix-cut "distro-image-sync:source-prepare-pull"

				return 0
			;;
			--all-projects)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				Require ListDistroDeclares
				indexAllJobs="$( ListDistroDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX --all-declares-prefix-cut "distro-image-sync:source-prepare-pull:" )"
	
				break
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
				if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						DistroSourcePrepare --explicit-noop $MDSC_NO_CACHE $MDSC_NO_INDEX --all-projects \
					)
					break
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

	echo "$indexAllJobs" >&2

}

case "$0" in
	*/sh-scripts/DistroSourcePrepare.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: DistroSourcePrepare.fn.sh [<options>] --all-projects" >&2
			echo "📘 syntax: DistroSourcePrepare.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "📘 syntax: DistroSourcePrepare.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
				echo >&2
				echo "  Options:" >&2
				echo >&2
				echo "    --explicit-noop" >&2
				echo "                Explicit argument that safely does nothing." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --merge-sequence" >&2
				echo "                Include all inherited provides for each project selected." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "    DistroSourcePrepare.fn.sh --all-projects" >&2
				echo >&2
				echo ""
			fi
			exit 1
		fi
		
		DistroSourcePrepare "$@"
	;;
esac
