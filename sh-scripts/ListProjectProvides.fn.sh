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

ListProjectProvides(){

	local MDSC_CMD='ListProjectProvides'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	local filterProjects=""

	set -e

	while true ; do
		case "$1" in
			--print-provides-only)
				shift
				ListProjectProvides "$projectName" "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break;
				#ListProjectProvides "$projectName" "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project provides filter is expected!" >&2
					set +e ; return 1
				fi
				local filterProvides="$1" projectProvides ; shift

				ListProjectProvides "$projectName" "$@" --print-provides-only \
				| while read -r projectProvides ; do
				 	if [ "$projectProvides" != "${projectProvides#${filterProvides}:}" ] ; then
						echo "$projectName ${projectProvides#${filterProvides}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListProjectSequence

				if [ -z "$1" ] ; then
					ListProjectSequence "$projectName" --print-provides
					return 0
				fi

				local sequenceProjectName
				ListProjectSequence "$projectName" \
				| while read -r sequenceProjectName ; do
					ListProjectProvides "$sequenceProjectName" "$@"
				done | awk '!x[$0]++'	
				return 0
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
		if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$projectName/project-provides.txt"
			local buildDate="$MDSC_CACHED/build-time-stamp.txt"
			if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
				[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi
	
			local repositoryName="$(echo "$projectName" | sed 's/\/.*$//')"
			local repositoryIndexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
	
			if [ -f "$repositoryIndexFile" ] ; then
				echo "$MDSC_CMD: $projectName: caching projects ($MDSC_OPTION)" >&2
				Require ListRepositoryProvides
				ListRepositoryProvides "$repositoryName" | grep -e "^$projectName " | tee "$cacheFile"
				# ListRepositoryProvides "$repositoryName" | grep -e "^$projectName " | sed 's/^.* //' | tee "$cacheFile"
				return 0
			fi
	
			mkdir -p "$MDSC_CACHED/$projectName"
			echo "$MDSC_CMD: $projectName: caching project provides ($MDSC_OPTION)" >&2
			ListProjectProvides --no-cache "$projectName" "$@" | tee "$cacheFile"
			return 0
		fi
		
		if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				
				echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
				
				for LINE in $( grep "PRJ-PRV-$projectName=" "$indexFile" | sed -e 's:^.*=::g' -e 's|\\:|:|g' ) ; do
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
				--print-provides-separate-lines
		)
		return 0
	fi
	
	echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectProvides.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectProvides.fn.sh <project_name> [--print-project] [--print-provides-only] [--merge-sequence] [--filter-and-cut filter_by]" >&2
			echo "📘 syntax: ListProjectProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
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
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common --print-provides-only --filter-and-cut deploy-export" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence" >&2
				echo "    ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-provides-only --filter-and-cut deploy-export --merge-sequence" >&2
				echo "	  ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project" >&2
				echo "	  ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence" >&2
				echo "	  ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project " >&2
			fi
			exit 1
		fi
		
		ListProjectProvides "$@"
	;;
esac
