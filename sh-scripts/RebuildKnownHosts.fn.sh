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

RebuildKnownHosts() {
	if [ -z "$MDSC_SOURCE" ]; then
		echo "⛔ ERROR: DistroContext is not set!" >&2
		set +e ; return 1
	fi

	mkdir -p "$MMDAPP/ssh"

	local DEST="$MMDAPP/ssh/known_hosts"

	if ! touch "$DEST.$$.tmp"; then
		echo "⛔ ERROR: Can't make temporary file $DEST.$$.tmp, exiting..." >&2
		set +e ; return 1
	fi

	[ -z "$MDSC_DETAIL" ] || echo "RebuildKnownHosts: Using temporary file: $DEST.$$.tmp" >&2


	local projectName fileName

	{

		# all known hosts
		DistroSystemContext --index-projects cat \
		| while read -r projectName; do
				[ full != "$MDSC_DETAIL" ] || echo "RebuildKnownHosts: projectName=${projectName}" >&2
				if [ -f "$MDSC_SOURCE/$projectName/ssh/known_hosts" ]; then
					fileName="$MDSC_SOURCE/$projectName/ssh/known_hosts"
				elif [ -f "$MMDAPP/source/$projectName/ssh/known_hosts" ]; then
					fileName="$MMDAPP/source/$projectName/ssh/known_hosts"
				else
					continue
				fi

				[ -z "$addComment" ] || printf '\n\n## Source: %s\n\n' "$projectName"
				sort -t' ' -k1,1  "$fileName" \
				| sed 's/[[:space:]]\{1,\}/\t/g' \
				| column -t -s $'\t'
		done

		# previous known hosts
		if [ "--no-delete" != "$1" ] && [ -s "$DEST" ]; then
			printf "\n\n## Stale, non-removed records:\n\n"
			cat "$DEST" \
			| awk '!$0 && $0 !~ /^#/ && !seen[$0]++'
		fi

	} \
	| awk '!$0 || $0 ~ /^#/ || !seen[$1]++' \
	| uniq \
	>> "$DEST.$$.tmp"
	
	chmod 664 "$DEST.$$.tmp"
	mv -f -- "$DEST.$$.tmp" "$DEST"
}

case "$0" in
*/sh-scripts/RebuildKnownHosts.fn.sh)
	RebuildKnownHosts "$@"
	;;
esac
