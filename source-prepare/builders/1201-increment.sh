#!/bin/sh

[ "full" != "$MDSC_DETAIL" ] || set -x

Require ListDistroProvides
ListDistroProvides --select-changed --filter-and-cut "source-prepare:increment" \
| { grep -e " build.number$" || [ $? -eq 1 ] ; } \
| cut -d" " -f1 | while read -r projectName ; do
	CHECK_FILE="$MMDAPP/source/${projectName#$MMDAPP/source/}/build.number"
	if [ -f "$CHECK_FILE" ] ; then
		echo "build.number: $projectName: INCREMENT!" >&2
	else
		echo "build.number: $projectName: INIT!" >&2
	fi
done
