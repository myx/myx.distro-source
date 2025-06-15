#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListChangedSourceProjects(){
	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/changed-project-names.txt"
		if [ -n "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListChangedSourceProjects: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListChangedSourceProjects: caching projects ($MDSC_OPTION)" >&2
			ListChangedSourceProjects --no-cache | tee "$cacheFile"
			return 0
		fi
	fi
	
	Require ListDistroProjects

	if [ -d "$MDSC_CACHED/changed" ] ; then
		local projectName=""
		for projectName in ` ListDistroProjects --all-projects ` ; do
			if [ -f "$MDCS_CACHED/changed/$projectName" ] ; then
				echo "$projectName"
			fi
		done	
		return 0
	fi
	
	ListDistroProjects --all-projects
}

case "$0" in
	*/sh-scripts/ListChangedSourceProjects.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListChangedSourceProjects "$@"
	;;
esac
