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

ListProjectDeclares(){

	local MDSC_CMD='ListProjectDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2 ; return 1
	fi
	shift

	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--print-declares-only)
				shift
				ListProjectDeclares "$projectName" $useNoCache $useNoIndex "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break;
				#ListProjectDeclares "$projectName" $useNoCache $useNoIndex "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: project declares filter is expected!" >&2 ; return 1
				fi
				local filterDeclares="$1" projectDeclares ; shift

				ListProjectDeclares "$projectName" $useNoCache $useNoIndex "$@" --print-declares-only \
				| while read -r projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListProjectSequence

				if [ -z "$1" ] ; then
					ListProjectSequence "$projectName" $useNoCache $useNoIndex --print-declares
					return 0
				fi

				local sequenceProjectName
				ListProjectSequence "$projectName" $useNoCache $useNoIndex \
				| while read -r sequenceProjectName ; do
					ListProjectDeclares "$sequenceProjectName" $useNoCache $useNoIndex "$@"
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
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2 ; return 1
			;;
		esac
	done

	if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$useNoCache" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$projectName/project-declares.txt"
	
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
				Require ListRepositoryDeclares
				ListRepositoryDeclares "$repositoryName" | grep -e "^$projectName " | tee "$cacheFile"
				# ListRepositoryDeclares "$repositoryName" | grep -e "^$projectName " | sed 's/^.* //' | tee "$cacheFile"
				return 0
			fi
	
			mkdir -p "$MDSC_CACHED/$projectName"
			echo "$MDSC_CMD: $projectName: caching project declares ($MDSC_OPTION)" >&2
			ListProjectDeclares "$projectName" --no-cache "$@" | tee "$cacheFile"
			return 0
		fi
		
		if [ "$useNoIndex" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				
				echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
				
				for LINE in $( grep "PRJ-DCL-$projectName=" "$indexFile" | sed -e 's:^.*=::g' -e 's|\\:|:|g' ) ; do
					echo $projectName $LINE
				done
				
				return 0
			fi
		fi
	fi
	
	if [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2
		(
			Require ListSourceProjectDeclares
			ListSourceProjectDeclares "$projectName"
		)
		return 0
	fi
	
	echo "ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectDeclares.fn.sh)
		# ListProjectDeclares.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDeclares.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDeclares.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz 
		# ListProjectDeclares.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz --merge-sequence --print-project 
		# ListProjectDeclares.fn.sh ndm/cloud.dev/setup.host-ndss-hz.ndm9.xyz --merge-sequence 
		# ListProjectDeclares.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --print-project deploy-keyword
		# ListProjectDeclares.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence deploy-keyword
		# ListProjectDeclares.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence --print-project deploy-keyword
		# ListProjectDeclares.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz --merge-sequence deploy-keyword
	
		# ListProjectDeclares.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-c1 2> /dev/null
		# ListProjectDeclares.fn.sh --distro-from-cached ndm/cloud-infra/setup.assets-infra/location-c1 2> /dev/null

		# ListProjectDeclares.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-c1 --merge-sequence 2> /dev/null
		# ListProjectDeclares.fn.sh --distro-from-cached ndm/cloud-infra/setup.assets-infra/location-c1 --merge-sequence 2> /dev/null

		# ListProjectDeclares.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-c1 deploy-keyword 2> /dev/null
		# ListProjectDeclares.fn.sh --distro-from-cached ndm/cloud-infra/setup.assets-infra/location-c1 deploy-keyword 2> /dev/null

		# ListProjectDeclares.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-c1 --print-project deploy-keyword 2> /dev/null
		# ListProjectDeclares.fn.sh --distro-from-cached ndm/cloud-infra/setup.assets-infra/location-c1 --print-project deploy-keyword 2> /dev/null
	
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListProjectDeclares.fn.sh <project_name> [--print-project] [--print-declares-only] [--merge-sequence] [--filter-and-cut filter_by]" >&2
			echo "syntax: ListProjectDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-declares-only --filter-and-cut deploy-export" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence" >&2
				echo "    ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-declares-only --filter-and-cut deploy-export --merge-sequence" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence" >&2
				echo "	  ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project " >&2
			fi
			exit 1
		fi
		
		ListProjectDeclares "$@"
	;;
esac