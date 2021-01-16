#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListDistroRequires(){
	set -e
	
	Require ListAllRepositories
	Require ListRepositoryRequires

	# ListAllRepositories | xargs -I % bash -c "ListRepositoryRequires.fn.sh %"
	# return 0

	local repositoryName
	ListAllRepositories | while read -r repositoryName ; do
		ListRepositoryRequires "$repositoryName" "$@"
	done
}

case "$0" in
	*/sh-scripts/ListDistroRequires.fn.sh)
		# ListDistroRequires.fn.sh --distro-from-source
		# ListDistroRequires.fn.sh --distro-source-only
		# ListDistroRequires.fn.sh myx --merge-sequence 
		# ListDistroRequires.fn.sh myx deploy-keyword
		# ListDistroRequires.fn.sh myx --merge-sequence deploy-keyword
		# ListDistroRequires.fn.sh --distro-from-source prv --no-cache source-prepare
		# ListDistroRequires.fn.sh --distro-from-source prv --merge-sequence --no-cache source-prepare

		if [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroRequires.fn.sh [--help] <repository_name> [--merge-sequence] [--no-cache] [filter_by]" >&2
			exit 1
		fi

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		ListDistroRequires "$@"
	;;
esac