#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi



ListAllProjects(){
	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/all-project-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			echo "ListAllProjects: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListAllProjects: caching projects ($MDSC_OPTION)" >&2
			ListAllProjects --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$MDSC_CACHED/distro-index.inf" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$MDSC_CACHED/distro-index.inf" "+%Y%m%d%H%M%S"`" ] ) ; then
		echo "ListAllProjects: using image ($MDSC_OPTION)" >&2
		local PKG
		for PKG in $( cat "$MDSC_CACHED/distro-index.inf" | grep "PRJS=" | sed "s:^.*=::" | tr ' ' '\n' ) ; do
			echo "$PKG"
		done
		return 0
	fi
	
	type ListAllRepositories >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListAllRepositories.fn.sh"
	
	type ListAllRepositoryProjects >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListAllRepositoryProjects.fn.sh"
	
	echo "ListAllProjects: scanning all projects ($MDSC_OPTION)" >&2
	for REPO in $( ListAllRepositories ) ; do
		ListAllRepositoryProjects "$REPO"
	done
	return 0
}

case "$0" in
	*/sh-scripts/ListAllProjects.fn.sh) 
		#	ListAllProjects.fn.sh
		#	( . "`which ListAllProjects.fn.sh`" ; ListAllProjects )
		#	ListAllProjects.fn.sh --distro-from-output
		#	ListAllProjects.fn.sh --distro-from-cached
		#	ListAllProjects.fn.sh --distro-from-distro
		#	ListAllProjects.fn.sh --distro-from-source

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		ListAllProjects "$@"
	;;
esac