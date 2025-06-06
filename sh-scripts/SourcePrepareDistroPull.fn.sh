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

if ! type DistroSource >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/lib.distro-source.include"
fi

SourcePrepareDistroPull(){
	local MDSC_CMD='SourcePrepareDistroPull'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	local useNoCache=""
	local useNoIndex=""

	case "$1" in
		--all-*)
		;;
		--explicit-noop)
			shift
		;;
		--no-cache)
			shift
			local useNoCache="--no-cache"
		;;
		--no-index)
			shift
			local useNoIndex="--no-index"
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--set-env)
			shift
			if [ -z "$1" ] ; then
				echo "ERROR: $MDSC_CMD: --set-env argument expected!" >&2
				set +e ; return 1
			fi
			local envName="$1" ; shift
			eval "$envName='` $MDSC_CMD --explicit-noop "$@" `'"
			return 0
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default SourcePrepareDistroPull "$@"
			return 0
		;;
	esac

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllJobs=""

	while true ; do
		case "$1" in
			--all-tasks)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
	
				Require ListDistroDeclares
				ListDistroDeclares $useNoCache $useNoIndex --all-declares-prefix-cut "distro-image-sync:source-prepare-pull"

				return 0
			;;
			--all-projects)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				Require ListDistroDeclares
				indexAllJobs="$( ListDistroDeclares $useNoCache $useNoIndex --all-declares-prefix-cut "distro-image-sync:source-prepare-pull:" )"
	
				break
			;;
			--merge-sequence)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "ERROR: $MDSC_CMD: --merge-sequence, no projects selected!" >&2
					set +e ; return 1
				fi
				
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectDeclares "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'

				return 0
			;;
			'')
				if [ ! -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						SourcePrepareDistroPull --explicit-noop $useNoCache $useNoIndex --all-projects \
					)
					break
				fi

				echo "ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			;;
			*)
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	echo "$indexAllJobs" >&2

}

case "$0" in
	*/sh-scripts/SourcePrepareDistroPull.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: SourcePrepareDistroPull.fn.sh [<options>] --all-projects" >&2
			echo "syntax: SourcePrepareDistroPull.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "syntax: SourcePrepareDistroPull.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
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
				echo "    SourcePrepareDistroPull.fn.sh --all-projects" >&2
				echo >&2
				echo ""
			fi
			exit 1
		fi
		
		SourcePrepareDistroPull "$@"
	;;
esac
