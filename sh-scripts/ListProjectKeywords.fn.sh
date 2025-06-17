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

ListProjectKeywords(){

	local MDSC_CMD='ListProjectKeywords'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--print-keywords-only)
				shift
				ListProjectKeywords "$projectName" $useNoCache $useNoIndex "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break;
				#ListProjectKeywords "$projectName" $useNoCache $useNoIndex "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local filterKeywords="$1" projectKeywords ; shift

				ListProjectKeywords "$projectName" $useNoCache $useNoIndex "$@" --print-keywords-only \
				| while read -r projectKeywords ; do
				 	if [ "$projectKeywords" != "${projectKeywords#${filterKeywords}:}" ] ; then
						echo "$projectName ${projectKeywords#${filterKeywords}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListProjectSequence

				if [ -z "$1" ] ; then
					ListProjectSequence "$projectName" $useNoCache $useNoIndex --print-keywords
					return 0
				fi

				local sequenceProjectName
				ListProjectSequence "$projectName" $useNoCache $useNoIndex \
				| while read -r sequenceProjectName ; do
					ListProjectKeywords "$sequenceProjectName" $useNoCache $useNoIndex "$@"
				done | awk '!x[$0]++'	
				return 0
			;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				useNoIndex=$1 ; shift
			;;
			'')
				break;
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$projectName/project-keywords.txt"
	
			if [ -f "$cacheFile" ] && \
				( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile" | sed "s|^|$projectName |g"
				return 0
			fi
	
			local repositoryName="$(echo "$projectName" | sed 's/\/.*$//')"
			local repositoryIndexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
	
			if [ -f "$repositoryIndexFile" ] ; then
				echo "$MDSC_CMD: $projectName: caching projects ($MDSC_OPTION)" >&2
				Require ListRepositoryKeywords
				ListRepositoryKeywords "$repositoryName" | grep -e "^$projectName " | tee "$cacheFile"
				# ListRepositoryKeywords "$repositoryName" | grep -e "^$projectName " | sed 's/^.* //' | tee "$cacheFile"
				return 0
			fi
	
			mkdir -p "$MDSC_CACHED/$projectName"
			echo "$MDSC_CMD: $projectName: caching project keywords ($MDSC_OPTION)" >&2
			ListProjectKeywords "$projectName" --no-cache "$@" | tee "$cacheFile"
			return 0
		fi
		
		if [ "$useNoIndex" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				
				echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
				
				for LINE in $( grep "PRJ-KWD-$projectName=" "$indexFile" | sed -e 's:^.*=::g' -e 's|\\:|:|g' ) ; do
					echo $projectName $LINE
				done
				
				return 0
			fi
		fi
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2
		(
			Require DistroSourceCommand
			DistroSourceCommand \
				-q \
				--import-from-source \
					--select-project "$projectName" \
				--print-keywords-separate-lines
		)
		return 0
	fi
	
	echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectKeywords.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectKeywords.fn.sh <project_name> [--print-project] [--print-keywords-only] [--merge-sequence] [--filter-and-cut filter_by]" >&2
			echo "syntax: ListProjectKeywords.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --print-keywords-only --filter-and-cut deploy-export" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence" >&2
				echo "    ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-keywords-only --filter-and-cut deploy-export --merge-sequence" >&2
				echo "	  ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project" >&2
				echo "	  ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence" >&2
				echo "	  ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project " >&2
			fi
			exit 1
		fi
		
		ListProjectKeywords "$@"
	;;
esac
