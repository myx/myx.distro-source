#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListRepositoryProjectsInternalRecursionEchoProjects(){
	local PKG_PATH="$1"
	
	[ -z "$PKG_PATH" ] && echo 'ERROR: $PKG_PATH' is not set! >&2 && return 1
	
	[ ! -d "$PKG_PATH" ] && return 0
	
	[ -f "$PKG_PATH/project.inf" ] && echo "$PKG_PATH" && return 0
	
	[ -d "$PKG_PATH/ae3-packages" ] && echo "$PKG_PATH" && return 0
	
	local SEARCH_DEPTH="$2"
	if [ "$SEARCH_DEPTH" != "--" ] ; then
		for CHK_PATH in `find "$PKG_PATH" -mindepth 1 -maxdepth 1 -type d | sort` ; do
			ListRepositoryProjectsInternalRecursionEchoProjects "$CHK_PATH" "-$SEARCH_DEPTH"
		done	
	fi
	
	return 0
}

ListRepositoryProjects(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListRepositoryProjects $@" >&2

	local repositoryName="${1#$MDSC_SOURCE/}"
	[ -z "$repositoryName" ] && echo 'ERROR: $repositoryName' is not set! >&2 && return 1
	
	if [ "$2" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/$repositoryName/project-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryProjects: $repositoryName: using cached ($MDSC_OPTION)" >&2
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
		for PKG in $( grep "PRJS=" "$MDSC_CACHED/$repositoryName/repository-index.inf" | sed "s:^.*=::" | tr ' ' '\n' ) ; do
			echo "$PKG"
		done
		return 0
	fi
	
	echo "ListRepositoryProjects: $repositoryName: scanning source folders ($MDSC_OPTION)" >&2
	
	for CHK_PATH in `find "$MDSC_SOURCE/$repositoryName" -mindepth 1 -maxdepth 1 -type d | sort` ; do
		for LINE in `ListRepositoryProjectsInternalRecursionEchoProjects "$CHK_PATH"` ; do
			echo "${LINE#$MDSC_SOURCE/}"
		done
	done	
}

case "$0" in
	*/sh-scripts/ListRepositoryProjects.fn.sh) 
		
		# ListRepositoryProjects.fn.sh myx
		# ListRepositoryProjects.fn.sh --distro-source-only myx 2> /dev/null
		# ListRepositoryProjects.fn.sh --distro-from-source myx 2> /dev/null
		# ListRepositoryProjects.fn.sh --distro-from-cached myx 2> /dev/null
		# ListRepositoryProjects.fn.sh myx --no-cache

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListRepositoryProjects "$@"
	;;
esac