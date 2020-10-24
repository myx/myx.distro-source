#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && return 1 )
fi


if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi


ListDistroProvides(){
	if [ "$1" = "--internal-print-project-provides" ] ; then
		shift
		if [ "$1" = "--filter" ] ; then
			shift
			local FILTER="$1" ; shift
			local projectName="$1" ; shift
			local ITEM="$@"
		 	if [ "$ITEM" != "${ITEM#$FILTER\\:}" ] ; then
				echo "$projectName ${ITEM#$FILTER\\:}" | tr '|' '\n'
			fi
			return 0
		fi
		local projectName="$1" ; shift
		for ITEM in "$@" ; do
			echo "$projectName $ITEM"
		done
		return 0
	fi

	local filterProjects=""
	while true ; do
		case "$1" in
			--filter-projects)
				shift
				filterProjects="$filterProjects --filter-projects $1" ; shift
				;;
			--filter-keywords)
				shift
				filterProjects="$filterProjects --filter-keywords $1" ; shift
				;;
			*)
				break
				;;
		esac
	done

	set -e
	
	local indexFile="$MDSC_CACHED/distro-index.inf"
	if [ -z "$filterProjects" ] && [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListRepositoryProvides: using index ($MDSC_OPTION)" >&2
		local MTC="^PRJ-PRV-"
		
		cat "$indexFile" | grep -e "$MTC" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' | while read -r LINE ; do
			ListDistroProvides --internal-print-project-provides $LINE
		done
		
		return 0
	fi
	
	if [ -z "$filterProjects" ] && [ "$MDSC_INMODE" = "source" ] ; then
		echo "ListRepositoryProvides: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-all \
			--print-provides-separate-lines
			
		return 0
	fi
	
	Require ListAllRepositories
	Require ListRepositoryProvides

	local repositoryName
	ListAllRepositories | while read -r repositoryName ; do
		ListRepositoryProvides $repositoryName $filterProjects "$@" || true
	done
}

case "$0" in
	*/sh-scripts/ListDistroProvides.fn.sh)
		# ListDistroProvides.fn.sh --distro-from-source | sort
		# ListDistroProvides.fn.sh --distro-from-cached | sort
		# ListDistroProvides.fn.sh --distro-source-only | sort
		# ListDistroProvides.fn.sh myx --merge-sequence | sort 
		# ListDistroProvides.fn.sh myx deploy-keyword
		# ListDistroProvides.fn.sh myx --merge-sequence deploy-keyword
		# ListDistroProvides.fn.sh --distro-from-source prv --no-cache source-prepare
		# ListDistroProvides.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare
		
		# ListDistroProvides.fn.sh --distro-source-only --distro-from-cached deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-source --distro-from-cached deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached --distro-from-cached deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached --distro-from-cached deploy-ssh-target 2> /dev/null

		# ListDistroProvides.fn.sh --distro-from-cached --distro-from-cached --filter-projects tbd9 deploy-ssh-target 2> /dev/null
		# ListDistroProvides.fn.sh --distro-from-cached --distro-from-cached --filter-projects tbd9 deploy-keyword 2> /dev/null

		if [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProvides.fn.sh [--help] <repository_name> [--merge-sequence] [--no-cache] [filter_by]" >&2
			exit 1
		fi
		
		ListDistroProvides "$@"
	;;
esac