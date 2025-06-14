#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )

"$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListDistroBuilders.fn.sh"
