#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


ListAllRepositories(){
	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/repository-names.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			echo "ListAllRepositories: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListAllRepositories: caching repositories ($MDSC_OPTION)" >&2
			ListAllRepositories --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	

	echo "ListAllRepositories: scanning all repositories ($MDSC_OPTION)" >&2
	for LINE in `find "$MDSC_SOURCE" -mindepth 2 -maxdepth 2 -name repository.inf | sort | sed 's!/repository.inf$!!'` ; do
		echo "${LINE#$MDSC_SOURCE/}"
	done
}

case "$0" in
	*/sh-scripts/ListAllRepositories.fn.sh) 
		#	ListAllRepositories.fn.sh
		#	( . "`which ListAllRepositories.fn.sh`" ; ListAllRepositories )
		#	ListAllRepositories.fn.sh --distro-from-output
		#	ListAllRepositories.fn.sh --distro-from-cached
		#	ListAllRepositories.fn.sh --distro-from-distro
		#	ListAllRepositories.fn.sh --distro-from-source

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		ListAllRepositories "$@"
	;;
esac