#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "`which rsync`" ] ; then
	echo "$0: rsync is required!" >&2
	exit 1
fi

type Prefix >/dev/null 2>&1 || \
	. "`myx.common which lib/prefix`"

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

Require PrepareProjectSyncToCached
Require ListRepositoryProjects

PrepareRepositorySyncToCached(){
	local repositoryName="${1#$MMDAPP/source/}"
	if [ -z "$repositoryName" ] ; then
		echo "PrepareRepositorySyncToCached: 'repositoryName' argument is required!" >&2 ; return 1
	fi
	
	mkdir -p "$MMDAPP/cached/sources/$repositoryName"
	rsync -a -i --delete "$MMDAPP/source/$repositoryName/repository.inf" "$MMDAPP/cached/sources/$repositoryName/repository.inf"

	for PKG in `ListRepositoryProjects "$repositoryName"` ; do
		Prefix "`basename $PKG`" PrepareProjectSyncToCached "$PKG"
	done
}

case "$0" in
	*/sh-scripts/PrepareRepositorySyncToCached.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-from-source
		
		PrepareRepositorySyncToCached "$@"
	;;
esac