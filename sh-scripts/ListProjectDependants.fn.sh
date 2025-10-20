#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectDependants(){

	local MDSC_CMD='ListProjectDependants'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
		local cacheFile="$MDSC_CACHED/$projectName/project-dependants.txt"
		local buildDate="$MDSC_CACHED/build-time-stamp.txt"
		if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi
		if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
			echo "$MDSC_CMD: $projectName: caching projects ($MDSC_OPTION)" >&2
			ListProjectDependants "$projectName" --no-cache | tee "$cacheFile"
			return 0
		fi
	fi
	
	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"
	if [ "0" = "1" ] && [ -n "$MDSC_CACHED" ] && [ -f "$indexFile" ] && \
		( [ -z "$BUILD_STAMP" ] || [ ! "$BUILD_STAMP" -gt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ) ; then
		
		echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
	
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
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--select-dependants \
			--print-sequence
		return 0
	fi
	
	echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectDependants.fn.sh) 
		# ListProjectDependants.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.example.org
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.example.org
		# ListProjectDependants.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-r4 2> /dev/null

		echo "⛔ ERROR: ListProjectDependants: not implemented?" >&2 ; exit 1

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectDependants "$@"
	;;
esac
