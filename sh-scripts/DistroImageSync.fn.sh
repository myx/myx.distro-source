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

DistroImageSync(){
	local MDSC_CMD='DistroImageSync'
	set -e

	case "$1" in
		--intern-print-all-tasks)
			[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $useNoCache $useNoIndex $@" >&2

			local projectName buildStage syncOperation targetSpec sourceSpec extra
			Require ListDistroDeclares
			ListDistroDeclares $useNoCache $useNoIndex --all-declares-prefix-cut "distro-image-sync" \
			| sed -e 's/:/ /' -e 's/:/ /' -e 's/:/ /' \
			| while read -r projectName buildStage syncOperation targetSpec sourceSpec extra ; do
				echo "$buildStage" "$projectName" "$syncOperation" "$targetSpec" "$sourceSpec" "$extra"
			done
			return 0
		;;
		--intern-print-repo-list-from-stdin)
			[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $useNoCache $useNoIndex $@" >&2

			while read -r buildStage projectName syncOperation targetSpec sourceSpec extra ; do
				if [ "." == "$targetSpec" ] ; then
					targetSpec="$projectName"
				fi
				case "$syncOperation" in
					repo)
						local sourceBranch sourceUrl
						echo "*$sourceSpec" | sed 's/:/ /' | if read -r sourceBranch sourceUrl ; then
							if [ -z "$sourceUrl" ] ; then
								echo "WARNING: $MDSC_CMD: no repo url spec in $projectName $buildStage:repo directive (ignoring)!" >&2
								continue
							fi
							echo "$targetSpec" "$sourceUrl" "${sourceBranch:1}"
						fi
					;;
					list)
						local listFile="$MDSC_SOURCE/$targetSpec/$sourceSpec"
						if [ ! -f "$listFile" ] ; then
							echo "WARNING: $MDSC_CMD: no repo list ($listFile) found for $projectName $buildStage:repo directive (ignoring)!" >&2
							continue
						fi

						local targetSpec sourceUrl sourceBranch
						cat "$listFile" \
						| while read -r targetSpec sourceUrl sourceBranch ; do
							if [ "${targetSpec:0:1}" == "#" ] || [ -z "$targetSpec" ] || [ -z "$sourceUrl" ] ; then
								continue
							fi
							echo "${targetSpec%%/}" "$sourceUrl" "$sourceBranch"
						done
					;;
					*)
						# echo "$MDSC_CMD: unknown sync operation: $syncOperation" >&2
					;;
				esac
			done | awk '$0 && !x[$0]++'
			return 0
		;;
		--intern-check-build-stage)
			[ "$MDSC_DETAIL" == "full" ] || echo "> $MDSC_CMD $useNoCache $useNoIndex $@" >&2

			shift
			case "$1" in
				source-prepare-pull|source-process-push|image-prepare-pull|image-process-push|image-install-pull)
					useStage="$1"
					return 0
				;;
			esac
			echo "ERROR: $MDSC_CMD: invalid build-stage: $1" >&2
			set +e ; return 1
		;;
		--intern-print-script-from-stdin-repo-list)
			[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $useNoCache $useNoIndex $@" >&2

			shift
			. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroImageSync-script-maker.include"
			return 0
		;;
		--intern-execute-script-from-stdin)
			[ "$MDSC_DETAIL" == "full" ] || echo "> $MDSC_CMD $useNoCache $useNoIndex $@" >&2
			( eval "$( cat )" )
			return 0
		;;
	esac

	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local useNoCache=""
	local useNoIndex=""
	local useJobList=""
	local useStage=""

	while true ; do
		case "$1" in
			--all-tasks)
				shift
				local useJobList="$( DistroImageSync $useNoCache $useNoIndex $useStage --print-all-tasks )"
				break
			;;
			--explicit-noop)
				shift
				break
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
				break
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
			--print-all-tasks)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				DistroImageSync --intern-print-all-tasks
				return 0
			;;
			--print-all-tasks-repo-list)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-tasks-repo-list option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				DistroImageSync --intern-print-all-tasks | DistroImageSync --intern-print-repo-list-from-stdin | sort
				return 0
			;;
			--print-*|--script-*|--execute-*)
				break
			;;
			--*)
				Require ListDistroProjects
				ListDistroProjects --select-execute-default DistroImageSync "$@"
				return 0
			;;
			*)
				break;
			;;
		esac
	done

	while true ; do
		case "${useCommand:-$1}" in
			--print-tasks)
			
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after $useCommand option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				echo "$useJobList"
				
				return 0
			;;
			--print-repo-list)
			
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after $useCommand option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				echo "$useJobList" \
				| DistroImageSync --intern-print-repo-list-from-stdin | sort
				
				return 0
			;;
			--print-*)
				local selectVariant="${1#--print-}"
				DistroImageSync --intern-check-build-stage "$selectVariant"
				shift
				
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after $useCommand option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				echo "$useJobList" \
				| grep -e "^${selectVariant}" \
				| DistroImageSync --intern-print-repo-list-from-stdin
				
				return 0
			;;
			--script-*)
				local selectVariant="${1#--script-}"
				DistroImageSync --intern-check-build-stage "$selectVariant"
				shift
				
				echo "$useJobList" \
				| grep -e "^${selectVariant}" \
				| DistroImageSync --intern-print-repo-list-from-stdin \
				| DistroImageSync --intern-print-script-from-stdin-repo-list "$@"
				
				return 0
			;;
			--execute-*)
				local selectVariant="${1#--execute-}"
				DistroImageSync --intern-check-build-stage "$selectVariant"
				shift
				
				echo "$useJobList" \
				| grep -e "^${selectVariant}" \
				| DistroImageSync --intern-print-repo-list-from-stdin \
				| DistroImageSync --intern-print-script-from-stdin-repo-list "$@" \
				| DistroImageSync --intern-execute-script-from-stdin
				
				return 0
			;;
			'')
				echo "ERROR: $MDSC_CMD: one of --print-* or --execute command is required" >&2
				set +e ; return 1

				if [ ! -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						DistroImageSync $useNoCache $useNoIndex $useStage --print-all-tasks \
					)
					break
				fi

				echo "ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			;;
			*)
				echo "ERROR: $MDSC_CMD: invalid option: ${useCommand:-$1}" >&2
				set +e ; return 1
			;;
		esac
	done
	return 0
}

case "$0" in
	*/sh-scripts/DistroImageSync.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DistroImageSync.fn.sh [<options>] --print-all-tasks" >&2
			echo "syntax: DistroImageSync.fn.sh [<options>] <project-selector> <operation>" >&2
			echo "syntax: DistroImageSync.fn.sh [<options>] --all-tasks --{print|execute}-source-{prepare-pull|process-push}" >&2
			echo "syntax: DistroImageSync.fn.sh [<options>] --all-tasks --{print|execute}-image-{prepare-pull|process-push}" >&2
			echo "syntax: DistroImageSync.fn.sh [<options>] --all-tasks <operation>" >&2
			echo "syntax: DistroImageSync.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				echo "    --all-tasks" >&2
				echo "                Select all distro tasks for all build stages." >&2
				echo >&2
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
				echo "  Operations:" >&2
				echo >&2
				echo "    --print-all-tasks" >&2
				echo "                Displays all sync tasks for all build stages from all projects in distro." >&2
				echo "                This command doesn't need project selector and any other arguments." >&2
				echo >&2
				echo "    --execute-source-prepare-pull [--parallel [N] / --sequence]" >&2
				echo "                Execute tasks for source-prapare pull stage (before source-prepare)." >&2
				echo >&2
				echo "    --execute-source-process-push [--parallel [N] / --sequence]" >&2
				echo "                Execute tasks for image-prapare push stage (on image-prepare, after source)." >&2
				echo >&2
				echo "    --execute-image-prepare-pull [--parallel [N] / --sequence]" >&2
				echo "                Execute tasks for image-prapare pull stage (on image-prepare, before deploy)." >&2
				echo >&2
				echo "    --execute-image-process-push [--parallel [N] / --sequence]" >&2
				echo "                Execute tasks for image-prapare push stage (on image-prepare, before deploy)." >&2
				echo >&2
				echo "    --execute-image-install-pull [--parallel [N] / --sequence]" >&2
				echo "                Execute tasks for image-install pull stage (on image-install, before deploy)." >&2
				echo >&2
				echo "    --print-tasks" >&2
				echo "                Display selected sync tasks for all build stages for selected projects." >&2
				echo >&2
				echo "    --print-repo-list" >&2
				echo "                Display selected tasks' unrolled sync lists (with repo lists expanded)." >&2
				echo >&2
				echo "    --print-source-{prepare-pull|process-push}" >&2
				echo "    --print-image-{prepare-pull|process-push}" >&2
				echo "                Displays syncronisation task list to be executed." >&2
				echo >&2
				echo "    --script-source-{prepare-pull|process-push} [--parallel [N] / --sequence]" >&2
				echo "    --script-image-{prepare-pull|process-push} [--parallel [N] / --sequence]" >&2
				echo "                Displays syncronisation script source to be executed." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "    DistroImageSync.fn.sh --print-all-tasks" >&2
				echo "    DistroImageSync.fn.sh --source-prepare-pull --print-all-tasks" >&2
				echo "    DistroImageSync.fn.sh --source-prepare-pull --all-tasks --print-tasks" >&2
				echo "    DistroImageSync.fn.sh --source-prepare-pull --print-all-tasks-repo-list" >&2
				echo "    DistroImageSync.fn.sh --source-prepare-pull --all-tasks --print-repo-list" >&2
				echo >&2
				echo ""
			fi
			exit 1
		fi
		
		DistroImageSync "$@"
	;;
esac
