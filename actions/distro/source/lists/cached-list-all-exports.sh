#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )

type ListDistroProjects >/dev/null 2>&1 || \
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListDistroProjects.fn.sh"

type ListProjectProvides >/dev/null 2>&1 || \
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListProjectProvides.fn.sh"


for projectName in `ListDistroProjects --all-projects` ; do
	for ITEM in `ListProjectProvides "$projectName" --print-provides-only --filter-and-cut deploy-export` ; do
		echo "$projectName: $( echo $ITEM | tr '\\' ' ' | sed "s|:| |g" )"
	done
done
