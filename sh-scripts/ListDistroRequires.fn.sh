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

ListDistroRequires(){
	local MDSC_CMD='ListDistroRequires'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	case "$1" in
		--all-requires|--all-requires-merged)
		;;
		--explicit-noop)
			shift
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
			ListDistroProjects --select-execute-default ListDistroRequires "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllKeywords=""
	local indexOwnKeywords=""
	local indexColumns=""

	while true ; do
		case "$1" in
			--all-requires)
				Require ListAllRepositories
				Require ListRepositoryRequires
			
				# ListAllRepositories | xargs -I % bash -c "ListRepositoryRequires.fn.sh %"
				# return 0
			
				local repositoryName
				ListAllRepositories | while read -r repositoryName ; do
					ListRepositoryRequires "$repositoryName" $useNoCache $useNoIndex "$@"
				done
	
				return 0
			;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			'')
				if [ ! -z "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ ! -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						ListDistroRequires --explicit-noop $useNoCache $useNoIndex --all-requires \
					)
					return 0
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

}

case "$0" in
	*/sh-scripts/ListDistroRequires.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroRequires.fn.sh --all-requires" >&2
			echo "syntax: ListDistroRequires.fn.sh --all-requires-merged" >&2
			echo "syntax: ListDistroRequires.fn.sh <project-selector> [--merge-sequence] [<options>]" >&2
			echo "syntax: ListDistroRequires.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpListDistroRequires.include"
			fi
			exit 1
		fi

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListDistroRequires "$@"
	;;
esac
