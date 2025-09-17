#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListAllRepositories(){

	local MDSC_CMD='ListAllRepositories'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2


	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--all-repositories)
				shift
				break
			;;
			--help)
				shift
				return 0
			;;
			'')
				break
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	if [ "$MDSC_NO_CACHE" != "--no-cache" ] && [ -n "$MDSC_CACHED" ] ; then
		local cacheFile="$MDSC_CACHED/repository-names.txt"
		if [ -f "$cacheFile" ] && \
			( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "$( date -u -r "$cacheFile" "+%Y%m%d%H%M%S" )" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -d "$MDSC_CACHED" ] ; then
			echo "$MDSC_CMD: caching repositories ($MDSC_OPTION)" >&2
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceNamespaces.include" \
			| tee "$cacheFile"
			return 0
		fi
	fi
	
	. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceNamespaces.include"
}

case "$0" in
	*/sh-scripts/ListAllRepositories.fn.sh) 
		#	ListAllRepositories.fn.sh
		#	( . "`which ListAllRepositories.fn.sh`" ; ListAllRepositories )
		#	ListAllRepositories.fn.sh --distro-source-only 2> /dev/null
		#	ListAllRepositories.fn.sh --distro-from-source 2> /dev/null
		#	ListAllRepositories.fn.sh --distro-from-cached 2> /dev/null
		#	ListAllRepositories.fn.sh --distro-from-output 2> /dev/null
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListAllRepositories "$@"
	;;
esac
