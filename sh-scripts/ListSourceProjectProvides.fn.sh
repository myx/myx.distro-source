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


ListSourceProjectProvides(){

	local MDSC_CMD='ListSourceProjectProvides'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2 ; return 1
	fi

	shift
	set -e

	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	while true ; do
		case "$1" in
			--print-provides-only)
				shift
				ListSourceProjectProvides "$projectName" "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break;
				#ListSourceProjectProvides "$projectName" $useNoCache $useNoIndex "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: project provides filter is expected!" >&2 ; return 1
				fi
				local filterProvides="$1" projectProvides ; shift

				ListSourceProjectProvides "$projectName" $useNoCache $useNoIndex "$@" --print-provides-only \
				| while read -r projectProvides ; do
				 	if [ "$projectProvides" != "${projectProvides#${filterProvides}:}" ] ; then
						echo "$projectName ${projectProvides#${filterProvides}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListSourceProjectSequence

				if [ -z "$1" ] ; then
					ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex --print-provides
					return 0
				fi

				local sequenceProjectName
				ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex \
				| while read -r sequenceProjectName ; do
					ListSourceProjectProvides "$sequenceProjectName" $useNoCache $useNoIndex "$@"
				done | awk '!x[$0]++'	
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
		-q \
		--import-from-source \
		--select-project "$projectName" \
		--print-provides-separate-lines

	#	--print-provides --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectProvides.fn.sh)
		# ListSourceProjectProvides.fn.sh "myx/clean-boot"
	 

		# . "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		# DistroShellContext --distro-from-source
		
		ListSourceProjectProvides "$@"
	;;
esac