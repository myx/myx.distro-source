#!/usr/bin/env bash

if [ -z "$MMDAPP" ]; then
	set -e
	export MMDAPP="$(
		cd $(dirname "$0")/../../../..
		pwd
	)"
	echo "$0: Working in: $MMDAPP" >&2
	[ -d "$MMDAPP/source" ] || (echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1)
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

Require ListDistroProjects
Require ListProjectKnownHosts

RebuildKnownHosts() {
	if [ -z "$MDSC_SOURCE" ]; then
		echo "⛔ ERROR: DistroContext is not set!" >&2
		set +e ; return 1
	fi

	local TMP_FILE
	TMP_FILE="$(mktemp -t "rebuild-knownhosts-XXXXXXXX")"
	if [ $? -ne 0 ]; then
		echo "⛔ ERROR: Can't make temporary file $TMP_FILE, exiting..." >&2
		set +e ; return 1
	fi

	echo "RebuildKnownHosts: Using temporary file: $TMP_FILE"

	mkdir -p "$MMDAPP/ssh"
	DEST="$MMDAPP/ssh/known_hosts"

	local projectName
	local knownHostsProject
	local knownHostsFile

	{

		# all known hosts
		for projectName in $(ListDistroProjects --all-projects); do
			ListProjectKnownHosts --add-comment "$projectName"
		done 

		# previous known hosts
		if [ "--no-delete" != "$1" ] && [ -s "$DEST" ]; then
			printf "\n\n## Stale, non-removed records:\n\n"
			cat "$DEST" \
			| awk ' $0 !~ /^#/ && !seen[$0]++' \
			| grep -v '^[[:space:]]*$' > "$TMP_FILE"
		fi

	} \
	| awk '!$0 || $0 ~ /^#/ || !seen[$1]++' \
	| uniq \
	> "$TMP_FILE"
	

	mv -f "$TMP_FILE" "$DEST"
}

case "$0" in
*/sh-scripts/RebuildKnownHosts.fn.sh)
	RebuildKnownHosts "$@"
	;;
esac
