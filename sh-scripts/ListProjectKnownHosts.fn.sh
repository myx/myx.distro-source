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

ListProjectKnownHosts(){

	local MDSC_CMD='ListProjectKnownHosts'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"

	local addComment

	while [ $# -gt 0 ]; do case "$1" in
		--add-comment) shift ; addComment=true ;;
		--help)
			echo "$MDSC_CMD: list project's (ssh) known hosts items." >&2
			return
		;;
		*) break ;;
	esac done

	local projectName="${1#$MDSC_SOURCE/}"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi

	[ ! -f "$MDSC_SOURCE/$projectName/ssh/known_hosts" ] || {
		[ -z "$addComment" ] || printf '\n\n## Source: %s\n\n' "$projectName"
		cat "$MDSC_SOURCE/$projectName/ssh/known_hosts" \
		| sort -t' ' -k1,1 \
		| sed 's/[[:space:]]\{1,\}/\t/g' \
		| column -t -s $'\t'
		return 0
	}
	
	[ "$MDSC_SOURCE" != "$MMDAPP/source" ] || return 0

	[ ! -f "$MMDAPP/source/$projectName/ssh/known_hosts" ] || {
		[ -z "$addComment" ] || printf '\n\n## Source: %s\n\n' "$projectName"
		cat "$MMDAPP/source/$projectName/ssh/known_hosts" \
		| sort -t' ' -k1,1 \
		| sed 's/[[:space:]]\{1,\}/\t/g' \
		| column -t -s $'\t'
		return 0
	}

	return 0
}

case "$0" in
	*/sh-scripts/ListProjectKnownHosts.fn.sh) 
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectKnownHosts.fn.sh <project>" >&2
			echo "📘 syntax: ListProjectKnownHosts.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "examples:" >&2
				echo "	ListProjectKnownHosts.fn.sh --distro-from-source myx/myx.distro-source 2> /dev/null" >&2
				echo "	ListProjectKnownHosts.fn.sh --distro-source-only myx/myx.distro-source 2> /dev/null" >&2
				echo "	ListProjectKnownHosts.fn.sh --distro-from-cached myx/myx.distro-source 2> /dev/null" >&2
			fi
			exit 1
		fi
		
		ListProjectKnownHosts "$@"
	;;
esac
