#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListRepositoryProjects(){
	local repositoryName="${1#$MDSC_SOURCE/}"
	[ -z "$repositoryName" ] && echo '$repositoryName' is not set! >&2 && return 1
	
	if [ "$2" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/$repositoryName/project-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "ListRepositoryProjects: $repositoryName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] && [ -d "$( dirname "$cacheFile" )" ] ; then
			echo "ListRepositoryProjects: $repositoryName: caching repositories ($MDSC_OPTION)" >&2
			ListRepositoryProjects "$repositoryName" --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	

	if [ ! -z "$MDSC_CACHED" ] && [ -f "$MDSC_CACHED/$repositoryName/repository-index.inf" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$MDSC_CACHED/$repositoryName/repository-index.inf" "+%Y%m%d%H%M%S"`" ] ) ; then
		echo "ListRepositoryProjects: $repositoryName: using image ($MDSC_OPTION)" >&2
		local PKG
		for PKG in $( cat "$MDSC_CACHED/$repositoryName/repository-index.inf" | grep "PRJS=" | sed "s:^.*=::" | tr ' ' '\n' ) ; do
			echo "$PKG"
		done
		return 0
	fi
	
	echo "ListRepositoryProjects: $repositoryName: scanning source folders ($MDSC_OPTION)" >&2
	
	type ListPublicFolders >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListPublicFolders.fn.sh"
	
	type CheckEchoSourceProject >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/CheckEchoSourceProject.fn.sh"
	
	for CHK_PATH in `ListPublicFolders "$MDSC_SOURCE/$repositoryName"` ; do
		for LINE in `CheckEchoSourceProject "$CHK_PATH"` ; do
			echo "${LINE#$MDSC_SOURCE/}"
		done
	done	
}

case "$0" in
	*/sh-scripts/ListRepositoryProjects.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListRepositoryProjects "$@"
	;;
esac