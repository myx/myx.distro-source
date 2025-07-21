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

ListRepositoryKeywords(){
	
	local MDSC_CMD='ListRepositoryKeywords'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2


	case "$1" in
		--internal-print-project-keywords)
			echo "${@:3}"  | tr ' ' '\n' | xargs -I % echo "$2" %
			return 0
		;;
	esac

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "⛔ ERROR: ListRepositoryKeywords: 'repositoryName' argument is required!" >&2
		set +e ; return 1
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

	while true ; do
		case "$1" in
			--filter-projects)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: ListRepositoryKeywords: project name filter is expected!" >&2
					set +e ; return 1
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
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
					ListProjectKeywords "$sequenceProjectName" "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListRepositorySequence
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" ) ; do
					ListProjectKeywords "$sequenceProjectName" --merge-sequence "$@"
				done	
				return 0
			;;
			--filter)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: ListRepositoryKeywords: project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local filterKeywords="$1" ; shift

				local filterKeywords="$1" projectName projectKeywords ; shift
				ListRepositoryKeywords "$repositoryName" $MDSC_NO_CACHE $MDSC_NO_INDEX "$@" \
				| while read -r projectName projectKeywords ; do
				 	if [ "$projectKeywords" != "${projectKeywords#${filterKeywords}:}" ] ; then
						echo "$projectName ${projectKeywords#${filterKeywords}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			'')
				break;
			;;
			*)
				echo "⛔ ERROR: ListRepositoryKeywords: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
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
		
		if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
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
	
	if [ -z "$MDSC_JAVAC" ] && command -v javac 2>/dev/null && [ "$MDSC_INMODE" = "source" ] && [ -f "$MMDAPP/.local/roots/$repositoryName.distro-namespace" ] ; then
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
	ListRepositoryProjects "$repositoryName" | while read -r projectName ; do
		ListProjectKeywords $projectName $MDSC_NO_CACHE $MDSC_NO_INDEX "$@" || true
	done
}

case "$0" in
	*/sh-scripts/ListRepositoryKeywords.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListRepositoryKeywords.fn.sh <repository_name> [<options>] [--print-keywords-only] [<search>] [--filter filter_by]" >&2
			echo "📘 syntax: ListRepositoryKeywords.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo >&2
				echo "    --all / --filter-projects <glob> / --filter <keywords-filter>" >&2
				echo >&2
				echo "  Options:" >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
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
