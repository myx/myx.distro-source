#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListChangedSourceProjects(){

	set -e

	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MMDAPP/.local/source-cache/all-changed.index.txt"
		local buildDate="$MDSC_CACHED/build-time-stamp.txt"
		if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListChangedSourceProjects: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListChangedSourceProjects: caching projects ($MDSC_OPTION)" >&2
			ListChangedSourceProjects --no-cache | tee "$cacheFile.$$.tmp"
			mv -f "$cacheFile.$$.tmp" "$cacheFile" || :
			return 0
		fi
	fi

	if [ -d "$MMDAPP/.local/source-cache/changed" ] ; then
		[ -z "$MDSC_DETAIL" ] || echo "| ListChangedSourceProjects: intersecting cached/changed with projects" >&2
		local projectName=
		DistroSystemContext --index-projects cat \
		| while read -r projectName; do
			[ ! -f "$MMDAPP/.local/source-cache/changed/$projectName" ] || echo "$projectName"
		done	
		return 0
	fi
	
	if [ -d "$MMDAPP/.local/source-cache/changed" ]; then
		[ -z "$MDSC_DETAIL" ] || echo "| ListChangedSourceProjects: using find in cached/changed" >&2
		( cd "$MMDAPP/.local/source-cache/changed" ; find . -type f -print0 | xargs -0 ls -1 -tr -- | sed 's|^\./||'	)
		return 0
	fi
	
	[ -z "$MDSC_DETAIL" ] || echo "| ListChangedSourceProjects: source-only mode, listing all projects" >&2
	DistroSystemContext --index-projects cat
}

case "$0" in
	*/sh-scripts/ListChangedSourceProjects.fn.sh) 

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListChangedSourceProjects "$@"
	;;
esac
