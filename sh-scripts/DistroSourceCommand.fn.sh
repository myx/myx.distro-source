#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-from-source
fi

#
# Runs DistroCommand by compiling it's source code to a temporary folder 
#
DistroSourceCommand(){

	[ -z "$MDSC_DETAIL" ] || set -x
	local MDSC_OUTPUT="${MDSC_OUTPUT:-$MMDAPP/output}"
	local MDSC_SOURCE="${MDSC_SOURCE:-$MMDAPP/source}"
	local MDSC_CACHED="${MDSC_CACHED:-$MMDAPP/output/cached}"

	if [ "$MDLT_ORIGIN" == "$MMDAPP/source" ] ; then
		local DIR_OUT="$MDSC_CACHED/myx/myx.distro-source"
		local DIR_SRC="$MDSC_SOURCE/myx/myx.distro-source"
	else
		local DIR_OUT="$MDLT_ORIGIN/cached/myx/myx.distro-source"
		local DIR_SRC="$MDLT_ORIGIN/myx/myx.distro-source"
	fi

	[ -z "${ENV_DISTRO_SOURCE_JAVA-}" ] || ( echo "⛔ ERROR: DistroSourceCommand." >&2 && exit 1 )
	set +x


	set -e

	if [ -f "$DIR_OUT/bin/ru/myx/distro/DistroSourceCommand.class" ] ; then
		java -cp "$DIR_OUT/bin" ru.myx.distro.DistroSourceCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi
	
	if [ -f "$DIR_SRC/bin/ru/myx/distro/DistroSourceCommand.class" ] ; then
		java -cp "$DIR_SRC/bin" ru.myx.distro.DistroSourceCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi
	
	if [ -f "$DIR_SRC/java/ru/myx/distro/DistroSourceCommand.java" ] ; then
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassClean.include"
		RunJavaClassClean \
			"myx/myx.distro-source" \
			ru.myx.distro.DistroSourceCommand \
			--output-root "$MDSC_OUTPUT" \
			--source-root "$MDSC_SOURCE" \
			--cached-root "$MDSC_CACHED" \
			"$@"
		return 0
	fi
	
	echo "DistroSourceCommand: No sources available, need to fetch!" >&2
	set +e ; return 1
}


case "$0" in
	*/sh-scripts/DistroSourceCommand.fn.sh) 
		# DistroSourceCommand.fn.sh --import-from-source --print-all-provides
		# DistroSourceCommand.fn.sh --import-from-source --select-all --print-provides-separate-lines
		# DistroSourceCommand.fn.sh -q --import-from-source --print-all-provides | sort
		# DistroSourceCommand.fn.sh -q --import-from-source --select-all --print-provides-separate-lines | sort
		
		# DistroSourceCommand.fn.sh --import-from-source --print-repo-provides lib
		# DistroSourceCommand.fn.sh --import-from-cached --print-repo-provides lib
		# DistroSourceCommand.fn.sh --import-from-source --select-repository lib --print-provides
		# DistroSourceCommand.fn.sh -q --import-from-source --select-repository lib --print-provides-separate-lines
		
		# DistroSourceCommand.fn.sh -q --import-from-source --select-project ndm/cloud-infra/setup.assets-infra/setup.host-n1h1.ndm9.xyz --print-provides-separate-lines
		# DistroSourceCommand.fn.sh -q --import-from-source --select-providers cloud-infra/setup.host-n1h1.ndm9.xyz --print-provides-separate-lines
		# DistroSourceCommand.fn.sh -q --import-from-source --select-providers cloud-infra/setup.host-n1h1.ndm9.xyz --select-required --print-provides-separate-lines
		
		# DistroSourceCommand.fn.sh --import-from-source --select-project lib/util.repository-lib --print-provides
		# DistroSourceCommand.fn.sh --import-from-source --select-providers ndm/location-c1 --print-provides
		
		# DistroSourceCommand.fn.sh --import-from-cached --select-project lib/util.repository-lib --print-provides
		# DistroSourceCommand.fn.sh --import-from-cached --select-providers ndm/location-c1 --print-provides
		
		# DistroSourceCommand.fn.sh --import-from-source --select-providers ndm/location-c1 --print-selected 2> /dev/null
		# DistroSourceCommand.fn.sh --import-from-cached --select-providers ndm/location-c1 --print-selected 2> /dev/null
		
		ENV_DISTRO_SOURCE_JAVA=javac \
		DistroSourceCommand "$@" --print ''
	;;
esac
