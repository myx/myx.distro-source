#!/bin/sh
###
### this script is included from builder
###

[ "full" != "$MDSC_DETAIL" ] || set -x

[ -z "${ENV_DISTRO_SOURCE_JAVA-}" ] || ( echo "⛔ ERROR: DistroSourceCommand." >&2 && exit 1 )

Distro DistroSourceCommand \
	-v \
	--import-from-source --select-all-from-source \
	--prepare-source-to-cached-index \
	--print '' \
