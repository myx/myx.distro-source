#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )

Distro ListAllBuilders --all-build-stages
