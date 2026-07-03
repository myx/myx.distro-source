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

# Gives: GitClonePull
. "$( myx.common which git/clonePull )"

SyncGitSource(){
	local MDSC_CMD='SyncGitSource'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2
	
	local projectPath="$MDSC_SOURCE/${1#"$MDSC_SOURCE/"}" ; shift
	if [ -z "$projectPath" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project path is expected!" >&2
		set +e ; return 1
	fi

	local repositorySpec="$1" ; shift
	if [ -z "$repositorySpec" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: repository spec is expected!" >&2
		set +e ; return 1
	fi

	if [ -n "$1" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: extra arguments in command!" >&2
		set +e ; return 1
	fi

	echo "$MDSC_CMD: 🔃 Syncing source project ${projectPath#"$MDSC_SOURCE/"} with git repository: $repositorySpec..." >&2
	GitClonePull "$projectPath" "$repositorySpec" "$@"
}

case "$0" in
	*/sh-scripts/SyncGitSource.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.SyncGitSource.include"
			exit 1
		fi
		
		SyncGitSource "$@"
	;;
esac
