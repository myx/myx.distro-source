#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListRepositoryProjectsInternalRecursionEchoProjects(){
	local PKG_PATH="$1"
	
	if [ -z "$PKG_PATH" ] ; then
		echo 'ERROR: $PKG_PATH' is not set! >&2
		set +e ; return 1
	fi
	
	[ ! -d "$PKG_PATH" ] && return 0
	
	[ -f "$PKG_PATH/project.inf" ] && echo "$PKG_PATH" && return 0
	
	[ -d "$PKG_PATH/ae3-packages" ] && echo "$PKG_PATH" && return 0
	
	local SEARCH_DEPTH="$2"
	if [ "$SEARCH_DEPTH" != "---" ] ; then
		for CHK_PATH in `find "$PKG_PATH" -mindepth 1 -maxdepth 1 -type d | sort` ; do
			ListRepositoryProjectsInternalRecursionEchoProjects "$CHK_PATH" "-$SEARCH_DEPTH"
		done	
	fi
	
	return 0
}

ListRepositoryProjects(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListRepositoryProjects $@" >&2

	local repositoryName="${1#$MDSC_SOURCE/}"
	if [ -z "$repositoryName" ] ; then
		echo 'ListRepositoryProjects: ERROR: $repositoryName' is not set! >&2
		set +e ; return 1
	fi
	shift
	
	local useNoCache=""
	local useNoIndex=""

	set -e

	while true ; do
		case "$1" in
			--all)
				shift
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
				echo "ERROR: ListRepositoryProjects: invalid option: $1" >&2
				set +e ; return 1
				;;
		esac
	done

	if [ "$useNoCache" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$repositoryName/project-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryProjects: $repositoryName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] && [ -d "$( dirname "$cacheFile" )" ] ; then
			echo "ListRepositoryProjects: $repositoryName: caching repositories ($MDSC_OPTION)" >&2
			ListRepositoryProjects "$repositoryName" --no-cache $useNoIndex | tee "$cacheFile"
			return 0
		fi
	fi
	

	if [ "$useNoIndex" != "--no-index" ] ; then
		local indexFile="$MDSC_CACHED/$repositoryName/repository-index.inf"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			echo "ListRepositoryProjects: $repositoryName: using image ($MDSC_OPTION)" >&2
			local PKG
			for PKG in $( grep "PRJS=" "$indexFile" | sed "s:^.*=::" | tr ' ' '\n' ) ; do
				echo "$PKG"
			done
			return 0
		fi
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
		
		# ListRepositoryProjects.fn.sh --distro-source-only myx 2> /dev/null
		# ListRepositoryProjects.fn.sh --distro-from-source myx 2> /dev/null
		# ListRepositoryProjects.fn.sh --distro-from-cached myx 2> /dev/null
		# ListRepositoryProjects.fn.sh myx --no-cache

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListRepositoryProjects.fn.sh <repository-name> [<options>]" >&2
			echo "syntax: ListRepositoryProjects.fn.sh [--help]" >&2
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
				echo "    ListRepositoryProjects.fn.sh myx" >&2
				echo "    ListRepositoryProjects.fn.sh myx --no-cache --no-index" >&2
			fi
			exit 1
		fi

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListRepositoryProjects "$@"
	;;
esac
