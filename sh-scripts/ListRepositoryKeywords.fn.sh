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

ListRepositoryKeywords(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListRepositoryKeywords $@" >&2

	case "$1" in
		--internal-print-project-keywords)
			echo "${@:3}"  | tr ' ' '\n' | xargs -I % echo "$2" %
			return 0
		;;
	esac

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositoryKeywords: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	set -e

	case "$1" in
		--print-keywords-only)
			shift
			ListRepositoryKeywords "$repositoryName" "$@" | awk '{print $2}'
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
					echo "ERROR: ListRepositoryKeywords: project name filter is expected!" >&2 ; return 1
				fi
				local projectFilter="$1" ; shift
				ListRepositoryKeywords "$repositoryName" "$@" | grep -e "^.*$projectFilter.* "
				return 0
			;;
			--print-project)
				shift
				
				Require ListRepositorySequence
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" $useNoCache $useNoIndex ) ; do
					ListProjectKeywords "$sequenceProjectName" $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListRepositorySequence
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" $useNoCache $useNoIndex ) ; do
					ListProjectKeywords "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@"
				done	
				return 0
			;;
			--filter)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListRepositoryKeywords: project keywords filter is expected!" >&2 ; return 1
				fi
				local filterKeywords="$1" ; shift

				local filterKeywords="$1" projectName projectKeywords ; shift
				ListRepositoryKeywords "$repositoryName" $useNoCache $useNoIndex "$@" \
				| while read -r projectName projectKeywords ; do
				 	if [ "$projectKeywords" != "${projectKeywords#${filterKeywords}:}" ] ; then
						echo "$projectName ${projectKeywords#${filterKeywords}:}"
					fi
				done | awk '!x[$0]++'
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
				echo "ERROR: ListRepositoryKeywords: invalid option: $1" >&2 ; return 1
			;;
		esac
	done

	if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$repositoryName/repository-keywords.txt"
			
			if [ -f "$cacheFile" ] && \
				( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryKeywords: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi

			echo "ListRepositoryKeywords: caching projects ($MDSC_OPTION)" >&2
			ListRepositoryKeywords $repositoryName --no-cache | tee "$cacheFile"
			return 0
		fi
		
		if [ "$useNoIndex" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryKeywords: using index ($MDSC_OPTION)" >&2
				local MTC="^PRJ-KWD-$repositoryName/"
				
				grep "$MTC" "$indexFile" | sed -e 's:^PRJ-KWD-::' -e 's:=: :g' -e 's|\\:|:|g' | while read -r LINE ; do
					ListRepositoryKeywords --internal-print-project-keywords $LINE
				done
			
				return 0
			fi
		fi
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$repositoryName/repository.inf" ] ; then
		echo "ListRepositoryKeywords: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--print-keywords-separate-lines
			
		return 0
	fi
	
	Require ListRepositoryProjects
	Require ListProjectKeywords

	local projectName
	ListRepositoryProjects | while read -r projectName ; do
		ListProjectKeywords $projectName $useNoCache $useNoIndex "$@" || true
	done
}

case "$0" in
	*/sh-scripts/ListRepositoryKeywords.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryKeywords.fn.sh <repository_name> [--print-keywords-only] [<search>] [--no-cache] [--filter filter_by]" >&2
			echo "syntax: ListRepositoryKeywords.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --all / --filter-projects <glob> / --filter-keywords <keyword>" >&2
				echo "  examples:" >&2
				echo "    ListRepositoryKeywords.fn.sh --distro-from-source myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh --distro-from-cached myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh --distro-source-only myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh myx --filter-projects macosx 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh myx --filter-projects clean | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh prv --filter-projects myx --filter-projects l6b2 --no-cache --no-index | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh prv --filter deploy-ssh-target 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh prv --filter image-execute:deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh --distro-source-only prv --filter image-execute:deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryKeywords.fn.sh ndm --print-project --merge-sequence --filter deploy-keyword" >&2
			fi
			exit 1
		fi
		
		ListRepositoryKeywords "$@"
	;;
esac