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

	case "$1" in
		--all)
			shift
		;;
		--filter-projects|--filter-keywords)
		;;
		*)
			echo "ERROR: ListDistroProvides: search-select argument is required!" >&2
			return 1
		;;
	esac

	set -e

	local useNoCache=""
	local useNoIndex=""

	local indexFile="$MDSC_CACHED/distro-index.inf"

	while true ; do
		case "$1" in
			--print-project)
				shift
				
				Require ListDistroSequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence --all $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
			;;
			--filter-projects)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project name filter is expected!" >&2 ; return 1
				fi
				local projectFilter="$1" ; shift
				ListDistroProvides --all "$@" | grep -e "^.*$projectFilter.* "
				return 0
			;;
			--filter-keywords)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project deploy keyword is expected!" >&2 ; return 1
				fi
				local keywordFilter="$1" ; shift

				Require ListProjectProvides

				ListDistroProvides --all | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' | while read -r LINE ; do
					ListProjectProvides "$LINE" --print-project "$@"
				done
				return 0
			;;
			--filter-keyword2)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project deploy keyword is expected!" >&2 ; return 1
				fi
				local keywordFilter="$1" ; shift
				join \
					<( ListDistroProvides --all --print-project "$@" ) \
					<( ListDistroProvides --all | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' )
				return 0;

				local projectList="$( ListDistroProvides --all "$@" | grep -e " deploy-keyword:$keywordFilter$" | awk '{print $1}' )"
				ListDistroProvides --all "$@" | while read -r LINE ; do
					echo grep -qe "$(echo $LINE | awk '{print $1}')"
					if grep -qe "$(echo $LINE | awk '{print $1}')" <<< $projectList ; then
						echo $LINE
					fi
				done
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListDistroSequence
				
				if [ "1" = "0" ] && [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
					if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						echo "ListDistroProvides: --merge-sequence using index ($MDSC_OPTION)" >&2

						local sequenceProjectName
						for sequenceProjectName in $( ListDistroSequence --all $useNoCache $useNoIndex ) ; do
							ListProjectProvides "$sequenceProjectName" --print-project --merge-sequence $useNoCache $useNoIndex "$@"
						done	
						return 0
						
						local MTC="^PRJ-PRV-"
						
						grep -e "$MTC" "$indexFile" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\:|:|g' | while read -r LINE ; do
							ListDistroProvides --internal-print-project-provides $LINE
						done
						
						return 0
					fi
				fi
				
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence --all $useNoCache $useNoIndex ) ; do
					ListProjectProvides "$sequenceProjectName" --print-project --merge-sequence $useNoCache $useNoIndex "$@"
				done	
				return 0
			;;
			--filter)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project provides filter is expected!" >&2 ; return 1
				fi
				local filterProvides="$1" ; shift

				ListDistroProvides --all $useNoCache $useNoIndex "$@" | while read -r LINE ; do
					ListDistroProvides --internal-print-project-provides --filter $filterProvides $LINE
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
			local cacheFile="$MDSC_CACHED/distro-provides.txt"
			
			if [ -f "$cacheFile" ] && \
				( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "ListDistroProvides: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi

			echo "ListDistroProvides: caching projects ($MDSC_OPTION)" >&2
			ListDistroProvides --all --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi

		if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
			if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
				
				echo "ListDistroProvides: using index ($MDSC_OPTION)" >&2
				local MTC="^PRJ-PRV-"
				
				grep -e "$MTC" "$indexFile" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\:|:|g' | while read -r LINE ; do
					ListDistroProvides --internal-print-project-provides $LINE
				done
				
				return 0
			fi
		fi
	fi
	
	if [ "$MDSC_INMODE" = "source" ] ; then
		echo "ListDistroProvides: extracting from source (java) ($MDSC_OPTION)" >&2

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
		ListRepositoryProvides $repositoryName $useNoCache $useNoIndex "$@" || true
	done
}

case "$0" in
	*/sh-scripts/ListDistroProvides.fn.sh)
		# 
		# 
		# ListDistroProvides.fn.sh myx deploy-keyword
		# ListDistroProvides.fn.sh myx --merge-sequence deploy-keyword
		# ListDistroProvides.fn.sh --distro-from-source prv --no-cache source-prepare
		# ListDistroProvides.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare
		
		# ! ListDistroProvides.fn.sh --merge-sequence deploy-keyword
		# ! ListDistroProvides.fn.sh --filter-keywords deploy-keyword
		# ! ListDistroProvides.fn.sh --merge-sequence deploy-keyword | grep " myx"
		
		
		# ListDistroProvides.fn.sh --distro-source-only deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-source deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached deploy-ssh-target 2> /dev/null

		# ListDistroProvides.fn.sh --distro-from-cached --filter-projects tbd9 deploy-ssh-target 2> /dev/null
		# ListDistroProvides.fn.sh --distro-from-cached --filter-projects tbd9 deploy-keyword 2> /dev/null

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProvides.fn.sh --all [--merge-sequence] [--no-cache] [--filter filter_by]" >&2
			echo "syntax: ListDistroProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  examples:" >&2
				echo "    ListDistroProvides.fn.sh --distro-from-source --all 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-from-cached --all | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-source-only --all | sort" >&2
				echo "    ListDistroProvides.fn.sh --filter-projects macosx 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --filter-projects myx | sort" >&2
				echo "    ListDistroProvides.fn.sh --filter-projects myx --filter-projects l6b2 --no-cache --no-index | sort" >&2
				echo "    ListDistroProvides.fn.sh --filter-keywords myx | sort" >&2
				echo "    ListDistroProvides.fn.sh --filter-keywords l6 | sort" >&2
				echo "    ListDistroProvides.fn.sh --all --filter deploy-ssh-target 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --all --filter deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-source-only --all --filter deploy-l6route-config 2> /dev/null | sort" >&2
			fi
			exit 1
		fi
		
		ListDistroProvides "$@"
	;;
esac