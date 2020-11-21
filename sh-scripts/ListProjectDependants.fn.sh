#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && return 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListProjectDependants(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "ListProjectDependants: 'projectName' argument is required!" >&2 ; return 1
	fi
	shift

	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/$projectName/project-dependants.txt"
		if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
			( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListProjectDependants: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListProjectDependants: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectDependants "$projectName" --no-cache > "$cacheFile"
			cat "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
	if [ ! -z "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListProjectDependants: $projectName: using index ($MDSC_OPTION)" >&2
		local MTC="^PRJ-SEQ-$projectName="
		
		local RESULT=""
	
		local FILTER="$1"
		if test -z "$FILTER" ; then
			for ITEM in `grep "$MTC" "$indexFile" | sed "s,^.*=,,g" | sort` ; do
				echo $ITEM
			done
		else
			for ITEM in `grep "$MTC" "$indexFile" | sed "s,^.*=,,g" | sort` ; do
				if test "$ITEM" != "${ITEM#${FILTER}:}" ; then
					echo ${ITEM#${FILTER}:} | tr "|" "\n"
				fi
			done
		fi
		return 0
	fi
	
	if [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "ListProjectDependants: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--select-dependants \
			--print-sequence
		return 0
	fi
	
	echo "ListProjectDependants: $projectName: project.inf file is required (at: $indexFile)" >&2 ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectDependants.fn.sh) 
		# ListProjectDependants.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-r4 2> /dev/null

		echo "ListProjectDependants: not implemented?" >&2 ; exit 1

		ListProjectDependants "$@"
	;;
esac