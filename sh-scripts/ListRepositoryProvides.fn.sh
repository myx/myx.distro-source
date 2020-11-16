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
	if [ "$1" = "--internal-print-project-provides" ] ; then
		shift
		if [ "$1" = "--filter" ] ; then
			shift
			local FILTER="$1" ; shift
			local projectName="$1" ; shift
			local ITEM="$@"
		 	if [ "$ITEM" != "${ITEM#${FILTER}:}" ] ; then
				echo "$projectName ${ITEM#${FILTER}:}" | tr '|' '\n'
			fi
			return 0
		fi
		local projectName="$1" ; shift
		for ITEM in "$@" ; do
			echo "$projectName $ITEM"
		done
		return 0
	fi

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: ListRepositoryProvides: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	shift

	set -e

	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
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
			--filter-projects)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListRepositoryProvides: project name filter is expected!" >&2 ; return 1
				fi
				local projectFilter="$1" ; shift
				ListRepositoryProvides "$repositoryName" "$@" | grep -e "^.*$projectFilter.* "
				return 0
			;;
			--filter-keywords)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: project deploy keyword is exepected!" >&2 ; return 1
				fi
				local keywordFilter="$1" ; shift

				Require ListProjectProvides

				ListRepositoryProvides "$repositoryName" | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' | while read -r LINE ; do
					ListProjectProvides "$LINE" --print-project "$@"
				done
				return 0
			;;
			--filter-keyword2)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListRepositoryProvides: project deploy keyword is expected!" >&2 ; return 1
				fi
				local keywordFilter="$1" ; shift
				join \
					<( ListRepositoryProvides "$repositoryName" --print-project "$@" ) \
					<( ListRepositoryProvides "$repositoryName" | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' )
				return 0;

				local projectList="$( ListRepositoryProvides "$repositoryName" "$@" | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' )"
				ListRepositoryProvides "$repositoryName" "$@" | while read -r LINE ; do
					echo grep -qe "$(echo $LINE | awk '{print $1}')"
					if grep -qe "$(echo $LINE | awk '{print $1}')" <<< $projectList ; then
						echo $LINE
					fi
				done
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListRepositorySequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListRepositorySequence "$repositoryName" $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" --print-project --merge-sequence $useNoCache $useNoIndex "$@"
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
					ListRepositoryProvides --internal-print-project-provides --filter "$filterProvides" $LINE
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
				echo "ListDistroProvides: invalid option: $1" >&2 ; return 1
			;;
		esac
	done

	if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$repositoryName/repository-provides.txt"
			
			if [ -f "$cacheFile" ] && \
				( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "ListRepositoryProvides: using cached ($MDSC_OPTION)" >&2
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
				[ -z "$MDSC_DETAIL" ] || echo "ListRepositoryProvides: using index ($MDSC_OPTION)" >&2
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
		# ListRepositoryProvides.fn.sh --distro-from-source myx
		# ListRepositoryProvides.fn.sh --distro-source-only myx
		# ListRepositoryProvides.fn.sh --distro-from-cached myx
		
		# ListRepositoryProvides.fn.sh --distro-source-only myx --merge-sequence 2> /dev/null
		# ListRepositoryProvides.fn.sh myx --merge-sequence
		# ListRepositoryProvides.fn.sh --distro-source-only myx --merge-sequence deploy-keyword 2> /dev/null
		# ListRepositoryProvides.fn.sh --distro-from-source myx --merge-sequence deploy-keyword 2> /dev/null
		# ListRepositoryProvides.fn.sh --distro-from-cached myx --merge-sequence deploy-keyword 2> /dev/null
		# ListRepositoryProvides.fn.sh myx --merge-sequence deploy-keyword
		
		# ListRepositoryProvides.fn.sh myx deploy-keyword
		# ListRepositoryProvides.fn.sh myx --filter-projects freebsd
		# ListRepositoryProvides.fn.sh myx --filter-projects freebsd deploy-export
		# ListRepositoryProvides.fn.sh myx --filter-keywords macosx
		# ListRepositoryProvides.fn.sh myx --filter-keywords macosx source-process
		# ListRepositoryProvides.fn.sh --distro-source-only myx --filter-keywords macosx 2> /dev/null 
		
		# ListRepositoryProvides.fn.sh ndm --print-project --merge-sequence deploy-keyword
		# ListRepositoryProvides.fn.sh ndm --print-project --merge-sequence deploy-keyword | grep bhyve
		
		### by project name
		# ListRepositoryProvides.fn.sh --distro-source-only myx --filter-projects common
		# ListRepositoryProvides.fn.sh --distro-from-source myx --filter-projects common
		# ListRepositoryProvides.fn.sh --distro-source-only myx --filter-projects macosx deploy-keyword
		# ListRepositoryProvides.fn.sh --distro-from-source myx --filter-projects macosx deploy-keyword
		
		# !!!! ListRepositoryProvides.fn.sh --distro-from-source myx --no-cache source-prepare
		# !!!! ListRepositoryProvides.fn.sh --distro-from-source myx --merge-sequence --no-cache source-prepare

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryProvides.fn.sh <repository_name> [--merge-sequence/--filter-projects <name_part>] [--no-cache] [--filter filter_by]" >&2
			echo "syntax: ListRepositoryProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
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
			fi
			exit 1
		fi
		
		ListRepositoryProvides "$@"
	;;
esac