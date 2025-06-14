#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "`which rsync`" ] ; then
	echo "ERROR: $0: rsync utility is required!" >&2
	exit 1
fi

type Prefix >/dev/null 2>&1 || \
	. "`myx.common which lib/prefix`"

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

Require ListAllRepositories
Require ListRepositoryProjects
Require SourcePrepareProjectSyncToCached

SourcePrepareRepositorySyncToCached(){
	local MDSC_CMD='SourcePrepareRepositorySyncToCached'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	local repositoryName="${1#$MMDAPP/source/}"
	if [ -z "$repositoryName" ] ; then
		echo "ERROR: $MDSC_CMD: 'repositoryName' argument is required!" >&2
		set +e ; return 1
	fi
	
	set -e

	mkdir -p "$MMDAPP/cached/sources/$repositoryName"
	rsync -ai --delete "$MMDAPP/source/$repositoryName/repository.inf" "$MMDAPP/cached/sources/$repositoryName/repository.inf" 2>&1 \
	| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || true)

	local packageName
	for packageName in `ListRepositoryProjects "$repositoryName"` ; do
		Prefix "`basename $packageName`" SourcePrepareProjectSyncToCached "$packageName"
	done
}

SourcePrepareDistroSyncToCached(){
	local MDSC_CMD='SourcePrepareDistroSyncToCached'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	if [ "$MDSC_INMODE" = "source" ] ; then
		local repositoryName
		ListAllRepositories \
		| while read -r repositoryName ; do
			Async -2 SourcePrepareRepositorySyncToCached "$repositoryName"
		done
		wait
		return 0
	fi

	# re-run itself with enforced 'source' mode
	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include" ; \
		DistroShellContext --distro-from-source ; \
		Distro SourcePrepareDistroSyncToCached "$@"
	)
}


case "$0" in
	*/sh-scripts/SourcePrepareDistroSyncToCached.fn.sh) 
		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-from-source

		SourcePrepareDistroSyncToCached "$@"
	;;
esac
