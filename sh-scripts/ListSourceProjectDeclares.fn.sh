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


ListSourceProjectDeclares(){

	local MDSC_CMD='ListSourceProjectDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi

	shift
	set -e


	local useNoCache=""
	local useNoIndex=""
	local filterProjects=""

	while true ; do
		case "$1" in
			--print-declares-only)
				shift
				ListSourceProjectDeclares "$projectName" "$@" | awk '!x[$2]++ {print $2}'
				return 0
			;;
			--print-project)
				shift
				break;
				#ListSourceProjectDeclares "$projectName" $useNoCache $useNoIndex "$@" # | sed "s|^|$projectName |g"
				#return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" projectDeclares ; shift

				ListSourceProjectDeclares "$projectName" $useNoCache $useNoIndex "$@" --print-declares-only \
				| while read -r projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				Require ListSourceProjectSequence

				if [ -z "$1" ] ; then
					ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex --print-declares
					return 0
				fi

				local sequenceProjectName
				ListSourceProjectSequence "$projectName" $useNoCache $useNoIndex \
				| while read -r sequenceProjectName ; do
					ListSourceProjectDeclares "$sequenceProjectName" $useNoCache $useNoIndex "$@"
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
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	Require DistroSourceCommand
	DistroSourceCommand \
		-q \
		--import-from-source \
		--select-project "$projectName" \
		--print-declares-separate-lines

	#	--print-declares --print ""
}

case "$0" in
	*/sh-scripts/ListSourceProjectDeclares.fn.sh)
		# ListSourceProjectDeclares.fn.sh "myx/clean-boot"
	 

		# . "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		# DistroShellContext --distro-from-source
	
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListSourceProjectDeclares.fn.sh <project_name> [--print-project] [--print-provides-only] [--merge-sequence] [--filter-and-cut filter_by]" >&2
			echo "syntax: ListSourceProjectDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-provides-only --filter-and-cut deploy-export" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence" >&2
				echo "    ListSourceProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-provides-only --filter-and-cut deploy-export --merge-sequence" >&2
				echo "	  ListSourceProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project" >&2
				echo "	  ListSourceProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence" >&2
				echo "	  ListSourceProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project " >&2
			fi
			exit 1
		fi
		
		ListSourceProjectDeclares "$@"
	;;
esac
