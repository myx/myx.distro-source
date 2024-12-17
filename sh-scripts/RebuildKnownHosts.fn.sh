#!/usr/bin/env bash

if [ -z "$MMDAPP" ]; then
	set -e
	export MMDAPP="$(
		cd $(dirname "$0")/../../../..
		pwd
	)"
	echo "$0: Working in: $MMDAPP" >&2
	[ -d "$MMDAPP/source" ] || (echo "ERROR: expecting 'source' directory." >&2 && exit 1)
fi

if ! type DistroShellContext >/dev/null 2>&1; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProjects
Require ListProjectKnownHosts

RebuildKnownHosts() {
	if [ -z "$MDSC_SOURCE" ]; then
		echo "ERROR: DistroContext is not set!" >&2
		return 1
	fi

	local TMP_FILE
	TMP_FILE="$(mktemp -t "rebuild-knownhosts-XXXXXXXX")"
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't make temporary file $TMP_FILE, exiting..." >&2
		return 1
	fi
	echo "Using temporary file: $TMP_FILE"

	mkdir -p "$MMDAPP/ssh"
	DEST="$MMDAPP/ssh/known_hosts"

	if [ "--no-delete" == "$1" ] && [ -s "$DEST" ]; then
		cat "$DEST" > "$TMP_FILE"
	fi

	local projectName
	local knownHostsProject
	local knownHostsFile

	for projectName in $(ListDistroProjects --all-projects); do
		for knownHostsProject in $(ListProjectKnownHosts "$projectName"); do
			if [ -f "$MDSC_SOURCE/$knownHostsProject" ]; then
				if [ "$MDSC_SOURCE" != "$MMDAPP/source" ] && [ -f "$MMDAPP/source/$knownHostsProject" ]; then
					knownHostsFile="$MMDAPP/source/$knownHostsProject"
				else
					knownHostsFile="$MDSC_SOURCE/$knownHostsProject"
				fi
			else
				knownHostsFile="$MMDAPP/source/$knownHostsProject"
			fi

			echo "Processing: ${knownHostsProject}" >&2
			(cat "$knownHostsFile"; echo;) | while read -r KEY PK_TYPE PK _; do
				if [ -n "$KEY" ] && [ -n "$PK_TYPE" ] && [ -n "$PK" ]; then
					KEY_ESCAPED="$(echo "${KEY}" | sed 's/[^^]/[&]/g; s/\^/\\^/g')"
					myx.common lib/replaceLine "$TMP_FILE" "^${KEY_ESCAPED} " "$KEY $PK_TYPE $PK"
				fi
			done
		done
	done
	sort -u "$TMP_FILE" | grep "\S" > "${DEST}"
	rm -rf "$TMP_FILE"
	echo "Result: ${DEST}"
}

case "$0" in
*/sh-scripts/RebuildKnownHosts.fn.sh)
	RebuildKnownHosts "$@"
	;;
esac
