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


ListSourceProjectSequence(){

	local MDSC_CMD='ListSourceProjectSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2 ; return 1
	fi

	shift
	set -e

	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
			--print-project)
				shift
				
				ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex "$@" | sed "s|^|$projectName |g"
				return 0
			;;
			--print-provides)
				shift
				
				Require ListSourceProjectProvides
		
				for sequenceProjectName in $( ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex ) ; do
					ListSourceProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex "$@"
				done | awk '!x[$2]++'
				# ListProjectSequence "$projectName" $useNoCache $useNoIndex "$@" | sed "s|^|$projectName |g"
				return 0
			;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			'')
				break;
			;;
			*)
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2 ; return 1
			;;
		esac
	done


	Require DistroSourceCommand
	DistroSourceCommand \
		--import-from-source \
		--select-project "$projectName" \
		--print-sequence-separate-lines


	#	--prepare-sequence \
	#	--print-sequence --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectSequence.fn.sh) 
		ListSourceProjectSequence "$@"
	;;
esac