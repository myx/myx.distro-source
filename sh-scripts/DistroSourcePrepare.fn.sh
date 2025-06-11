#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

MDSC_BIN="${MDSC_BIN:-${MDLC_BIN:-$MMDAPP/source}}"

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MDSC_BIN/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type DistroSource >/dev/null 2>&1 ; then
	. "$MDSC_BIN/myx/myx.distro-source/sh-lib/lib.distro-source.include"
fi

DistroSourcePrepare(){
	local MDSC_CMD='DistroSourcePrepare'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	local useNoCache=""
	local useNoIndex=""

	case "$1" in
		--prepare-register-repository-root)
			local repositoryName="$2"
			if [ -z "$repositoryName" ] ; then
				echo "ERROR: $MDSC_CMD: repository root name expected: $@" >&2
				set +e ; return 1
			fi
			shift
			shift

			(
				Require DistroSourceTools 
				DistroSourceTools --register-repository-root "$repositoryName" "$repositoryFetch"
			)

			echo "> $MDSC_CMD: --prepare-register-repository-root: creating source directory: $MMDAPP/source/$repositoryName" >&2
			mkdir -p "$MMDAPP/source/$repositoryName"
			echo "> $MDSC_CMD: --prepare-register-repository-root: creating: $MMDAPP/source/$repositoryName/repository.inf" >&2
			printf "# created at `date`\nName: $repositoryName\n" > "$MMDAPP/source/$repositoryName/repository.inf"

			local initialProject="$1"
			if [ ! -z "$initialProject" ] ; then
				shift

				( 
					Require DistroImageSync
					export useStage="source-prepare-pull"
					export syncMode="--parallel"
					eval "$( echo "$initialProject" | while read -r targetSpec sourceSpec sourceBranch ; do
						echo "source-prepare-pull $targetSpec repo $targetSpec $sourceBranch:$sourceSpec"
					done | DistroImageSync --intern-print-script-from-stdin-task-list )" 
				)
			fi

			if [ ! -z "$1" ] ; then
				echo "ERROR: $MDSC_CMD: no options allowed after --prepare-register-repository-root option ($MDSC_OPTION, $@)" >&2
				set +e ; return 1
			fi

			return 0
		;;
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
						DistroSourcePrepare --explicit-noop $useNoCache $useNoIndex --all-projects \
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
	*/sh-scripts/DistroSourcePrepare.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DistroSourcePrepare.fn.sh --prepare-register-repository-root <repo-name> [projects-spec-to-pull]" >&2
			echo "syntax: DistroSourcePrepare.fn.sh [<options>] --all-projects" >&2
			echo "syntax: DistroSourcePrepare.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "syntax: DistroSourcePrepare.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDSC_BIN/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
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
