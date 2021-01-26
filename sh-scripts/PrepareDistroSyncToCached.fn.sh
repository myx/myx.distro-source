#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-from-source
fi

Require ListAllRepositories
Require PrepareRepositorySyncToCached


PrepareDistroSyncToCached(){
	[ -z "$MDSC_DETAIL" ] || echo "> PrepareDistroSyncToCached $@" >&2

	if [ "$MDSC_INMODE" = "source" ] ; then
		local repositoryName
		ListAllRepositories \
		| while read -r repositoryName ; do
			Async -2 PrepareRepositorySyncToCached "$repositoryName"
		done
		wait
	else
		( \
			. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include" ; \
			DistroShellContext --distro-from-source ; \
			Distro PrepareDistroSyncToCached "$@"
		)
	fi
}


case "$0" in
	*/sh-scripts/PrepareDistroSyncToCached.fn.sh) 
		# PrepareDistroSyncToCached.fn.sh

		PrepareDistroSyncToCached "$@"
	;;
esac