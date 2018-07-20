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

ListDistroProvides(){
	set -e
	
	Require ListAllRepositories
	Require ListRepositoryProvides

	local repositoryName
	ListAllRepositories | while read repositoryName ; do
		ListRepositoryProvides "$repositoryName" "$@"
	done
}

case "$0" in
	*/sh-scripts/ListDistroProvides.fn.sh)
		# ListDistroProvides.fn.sh --distro-from-source
		# ListDistroProvides.fn.sh --distro-source-only
		# ListDistroProvides.fn.sh myx --merge-sequence 
		# ListDistroProvides.fn.sh myx deploy-keyword
		# ListDistroProvides.fn.sh myx --merge-sequence deploy-keyword
		# ListDistroProvides.fn.sh --distro-from-source prv --no-cache source-prepare
		# ListDistroProvides.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare

		if [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProvides.fn.sh [--help] <repository_name> [--merge-sequence] [--no-cache] [filter_by]" >&2
			exit 1
		fi

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListDistroProvides "$@"
	;;
esac