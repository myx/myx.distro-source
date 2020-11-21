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

ListRepositoryProvides(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListRepositoryProvides $@" >&2

	case "$1" in
		--internal-print-project-provides)
			echo "${@:3}"  | tr ' ' '\n' | xargs -I % echo "$2" %
			return 0
		;;
		--internal-print-project-provides-filter)
			shift
			local FILTER="$1" ; shift
			local projectName="$1" ; shift
			local ITEM="$@"
		 	if [ "$ITEM" != "${ITEM#${FILTER}:}" ] ; then
				echo "$projectName ${ITEM#${FILTER}:}"
			fi
			return 0
		;;
	esac

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositoryProvides: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	set -e

	case "$1" in
		--print-provides-only)
			shift
			ListRepositoryProvides "$repositoryName" "$@" | awk '{print $2}'
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
			--filter-projects)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListRepositoryProvides: project name filter is expected!" >&2 ; return 1
				fi
				local projectFilter="$1" ; shift
				ListRepositoryProvides "$repositoryName" "$@" | grep -e "^.*$projectFilter.* "
				return 0
			;;
			--print-project)
				shift
				
				Require ListRepositorySequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListRepositorySequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@"
				done	
				return 0
			;;
			--filter)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListRepositoryProvides: project provides filter is expected!" >&2 ; return 1
				fi
				local filterProvides="$1" ; shift

				ListRepositoryProvides "$repositoryName" $useNoCache $useNoIndex "$@" | while read -r LINE ; do
					ListRepositoryProvides --internal-print-project-provides-filter "$filterProvides" $LINE
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
				break;
			;;
			*)
				echo "ListRepositoryProvides: invalid option: $1" >&2 ; return 1
			;;
		esac
	done

	if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$repositoryName/repository-provides.txt"
			
			if [ -f "$cacheFile" ] && \
				( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryProvides: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi

			echo "ListRepositoryProvides: caching projects ($MDSC_OPTION)" >&2
			ListRepositoryProvides $repositoryName --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
		
		if [ "$useNoIndex" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryProvides: using index ($MDSC_OPTION)" >&2
				local MTC="^PRJ-PRV-$repositoryName/"
				
				grep "$MTC" "$indexFile" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\:|:|g' | while read -r LINE ; do
					ListRepositoryProvides --internal-print-project-provides $LINE
				done
			
				return 0
			fi
		fi
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
		echo "ListRepositoryProvides: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--print-provides-separate-lines
			
		return 0
	fi
	
	Require ListRepositoryProjects
	Require ListProjectProvides

	local projectName
	ListRepositoryProjects | while read -r projectName ; do
		ListProjectProvides $projectName $useNoCache $useNoIndex "$@" || true
	done
}

case "$0" in
	*/sh-scripts/ListRepositoryProvides.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryProvides.fn.sh <repository_name> [--print-provides-only] [<search>] [--no-cache] [--filter filter_by]" >&2
			echo "syntax: ListRepositoryProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --all / --filter-projects <glob> / --filter-keywords <keyword>" >&2
				echo "  examples:" >&2
				echo "    ListRepositoryProvides.fn.sh --distro-from-source myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh --distro-from-cached myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh --distro-source-only myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh myx --filter-projects macosx 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh myx --filter-projects clean | sort" >&2
				echo "    ListRepositoryProvides.fn.sh prv --filter-projects myx --filter-projects l6b2 --no-cache --no-index | sort" >&2
				echo "    ListRepositoryProvides.fn.sh prv --filter deploy-ssh-target 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh prv --filter deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh --distro-source-only prv --filter deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryProvides.fn.sh ndm --print-project --merge-sequence --filter deploy-keyword" >&2
			fi
			exit 1
		fi
		
		ListRepositoryProvides "$@"
	;;
esac