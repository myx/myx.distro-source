#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


ListAllProjectActions(){
	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"

	local CUT
	if [ "$1" = "--completion" ] ; then
		shift
		local CUT="${1#$MDSC_SOURCE/}/actions/"
	else
		local CUT=""
	fi

	local PKG="${1#$MDSC_SOURCE/}"
	if [ -z "$PKG" ] ; then
		echo "ListAllProjectActions: 'PKG' argument is required!" >&2 ; exit 1
	fi
	

	( \
		[ -d "$MDSC_SOURCE/$PKG/actions" ] && \
			( find "$MDSC_SOURCE/$PKG/actions" -mindepth 1 -type f -not -name '.*' | sed "s:^$MDSC_SOURCE/$CUT::g" ) ; \
		[ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -d "$MMDAPP/source/$PKG/actions" ] && \
			( find "$MMDAPP/source/$PKG/actions" -mindepth 1 -type f -not -name '.*' | sed "s:^$MMDAPP/source/$CUT::g" ) \
	) | sort | uniq
}

case "$0" in
	*/sh-scripts/ListAllProjectActions.fn.sh) 
		#	ListAllProjectActions.fn.sh --distro-from-source myx/myx.distro-source

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		ListAllProjectActions "$@"
	;;
esac