#!/bin/sh

[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )

Require ListDistroProjects
Require ListProjectProvides

projectName=
ListDistroProjects --all-projects \
| while read -r projectName; do
	for ITEM in $( ListProjectProvides "$projectName" --print-no-project --filter-and-cut deploy-export ) ; do
		echo "$projectName: $( printf '%s' "$ITEM" | tr '\\' ' ' | sed "s|:| |g" )"
	done
done
