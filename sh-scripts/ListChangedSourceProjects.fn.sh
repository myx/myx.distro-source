#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListChangedSourceProjects(){
	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/changed-project-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			echo "ListChangedSourceProjects: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListChangedSourceProjects: caching projects ($MDSC_OPTION)" >&2
			ListChangedSourceProjects --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	type ListAllProjects >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListAllProjects.fn.sh"

	if [ -d "$MDSC_CACHED/changed" ] ; then
		for PKG in $( ListAllProjects ) ; do
			if [ -f "$MDCS_CACHED/changed/$PKG" ] ; then
				echo "$PKG"
			fi
		done	
		return 0
	fi
	
	ListAllProjects
}

case "$0" in
	*/sh-scripts/ListChangedSourceProjects.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		ListChangedSourceProjects "$@"
	;;
esac