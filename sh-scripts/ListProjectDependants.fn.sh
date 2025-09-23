#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

ListProjectDependants(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: ListProjectDependants: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	if [ "$1" = "--no-cache" ] ; then
		shift
	else
		local cacheFile="$MDSC_CACHED/$projectName/project-dependants.txt"
		local buildDate="$MDSC_CACHED/build-time-stamp.txt"
		if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "| ListProjectDependants: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "ListProjectDependants: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectDependants "$projectName" --no-cache | tee "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
	if [ "0" = "1" ] && [ -n "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "ListProjectDependants: $projectName: using index ($MDSC_OPTION)" >&2
	
		local FILTER="$1"
		if test -z "$FILTER" ; then
			for ITEM in `grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed "s,^.*=,,g" | sort` ; do
				echo $ITEM
			done
		else
			for ITEM in `grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed "s,^.*=,,g" | sort` ; do
				if test "$ITEM" != "${ITEM#${FILTER}:}" ; then
					echo ${ITEM#${FILTER}:} | tr "|" "\n"
				fi
			done
		fi
		return 0
	fi
	
	if [ "0" = "1" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
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
	
	echo "⛔ ERROR: ListProjectDependants: $projectName: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectDependants.fn.sh) 
		# ListProjectDependants.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-r4 2> /dev/null

		echo "⛔ ERROR: ListProjectDependants: not implemented?" >&2 ; exit 1

		ListProjectDependants "$@"
	;;
esac
