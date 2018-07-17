#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroFromImage.include"

DistroFromImage \
	-v \
	--source-root "$MMDAPP/output" \
	--output-root "$MMDAPP/output" \
	--import-from-source \
	--prepare-build \
	--print ""

# /Volumes/ws-2017/myx-work/source/myx/myx.distro-source/sh-scripts/distro-source.sh --debug --import-from-source --build-distro-from-sources --print ''