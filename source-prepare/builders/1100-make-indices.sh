#!/bin/sh
###
### this script is included from builder
###

[ "full" != "$MDSC_DETAIL" ] || set -x

Require DistroSourceCommand

DistroSourceCommand \
	-vv \
	--import-from-source --select-all-from-source \
	--prepare-source-to-cached-index \
	--print '' \
