#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )

cd "$MMDAPP"
export MMDAPP
bash --rcfile "$MMDAPP/source/myx/myx.distro-source/sh-lib/console-source-bashrc.rc" -i "$@"
