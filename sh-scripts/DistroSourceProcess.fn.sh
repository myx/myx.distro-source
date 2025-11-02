#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

DistroSourceProcess(){

	local MDSC_CMD='DistroSourceProcess'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	set -e

	case "$1" in
		--ingest-distro-output-from-cached)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-process/SyncSourceOutputFromCached.include"

			local CACHE_ROOT="$MMDAPP/.local/output-cache"

			local NEW_CHANGED="$CACHE_ROOT/new-content.index.txt"
			if [ ! -s "$NEW_CONTENT" ]; then
				echo "< $MDSC_CMD IngestOutputFromCached.include: 🫙 no new index changes." >&2
				return 0
			fi

			local CACHE_DATE="$CACHE_ROOT/process-ingest.timestamp.txt"

			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: output cache timestamp expected: $CACHE_DATE" >&2
				set +e ; return 1
			}

			local BUILT_ROOT="$CACHE_ROOT/distro"; mkdir -p "$BUILT_ROOT"

			date -u "+%Y%m%d%H%M%S" > "$CACHE_ROOT/process-output.timestamp.txt"
			cp -f "$CACHE_DATE" "$BUILT_ROOT/build-time-stamp.txt"

			# local ALL_CHANGED="$CACHE_ROOT/all-changed.index.txt"
			# local ALL_PROJECTS="$CACHE_ROOT/all-projects.index.txt"
			# local ALL_NAMESPACES="$CACHE_ROOT/all-namespaces.index.txt"

			# cat "$ALL_NAMESPACES" > "$INDEX_ROOT/distro-namespaces.txt"
			# cat "$ALL_PROJECTS" > "$INDEX_ROOT/distro-projects.txt" # <<< this is not needed and not used, sequence is better
			# cat "$ALL_CHANGED" > "$INDEX_ROOT/changed-project-names.txt"

			return 0
		;;
		--ingest-distro-index-from-processed)
			shift

			local CACHE_ROOT="$MMDAPP/.local/output-cache"
			local INDEX_ROOT="$MMDAPP/.local/system-index"
			mkdir -p "$INDEX_ROOT"

			local CACHE_DATE="$CACHE_ROOT/process-ingest.timestamp.txt"
			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: output cache timestamp expected: $CACHE_DATE" >&2
				set +e ; return 1
			}

			local INDEX_DATE="$INDEX_ROOT/index-ingest.timestamp.txt"
			if [ ! -f "$INDEX_DATE" ] || [ "$INDEX_DATE" -ot "$CACHE_DATE" ] ; then
				cp -f "$CACHE_DATE" "$INDEX_DATE"
			fi

			(
				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/ScanSyncSystemIndexChanges.fn.include"
				ScanSyncSystemIndexChanges --execute-sync "$CACHE_ROOT/distro" "$INDEX_ROOT" || exit 1
			)

			DistroSystemContext --uncache-index
			[ -z "$MDSC_DETAIL" ] || echo "< $MDSC_CMD: system-index published." >&2

			return 0
		;;
		--ingest-distro-index-from-cached)
			shift
			DistroSourcePrepare --ingest-distro-output-from-cached
			DistroSourceProcess --ingest-distro-index-from-processed
			return 0
		;;
		--rebuild-output-index)
			shift

			if [ javac = "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 ; then
				[ -z "${ENV_DISTRO_SOURCE_JAVA-}" ] || ( echo "⛔ ERROR: DistroSourceCommand." >&2 && exit 1 )

				local indexFile="$MDSC_CACHED/distro-index.env.inf.txt"
				local buildDate="$MDSC_CACHED/build-time-stamp.txt"

				Distro DistroSourceCommand \
					-v$( 
						[ -z "$MDSC_DETAIL" ] || printf 'v' 
					) \
					--no-fail \
					--import-from-source --select-all-from-source \
					--prepare-source-to-cached-index \
					--print '' \
					--fail-if-errors \

				[ -f "$indexFile" ] || {
					echo "⛔ ERROR: $MDSC_CMD: distro-index.env.inf.txt is expected!" >&2
					set +e ; return 1
				}
				
				touch -r "$indexFile" "$buildDate"
			else
				DistroSourceProcess.fn.sh --clone-prepared-metadata
			fi

			# build index ready, prepare secondary indices

			ListDistroSequence.fn.sh --all >/dev/null

			ListDistroSequence.fn.sh --all-projects >/dev/null &
			ListDistroProjects.fn.sh --all-projects >/dev/null &
			ListDistroDeclares.fn.sh --all-declares >/dev/null &
			ListDistroKeywords.fn.sh --all-keywords >/dev/null &
			ListDistroProvides.fn.sh --all-provides >/dev/null &

			wait

			return 0
		;;
		--clone-prepared-metadata)
			shift
			local TGT_PROCESS="$MMDAPP/.local/output-cache/distro"

			local CACHE_ROOT="$MMDAPP/.local/output-cache/prepared"
			local CACHE_DATE="$CACHE_ROOT/../process-ingest.timestamp.txt"

			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: output cache timestamp expected: $CACHE_DATE" >&2
				set +e ; return 1
			}

			mkdir -p "$TGT_PROCESS"

			(
				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/ScanSyncSystemIndexChanges.fn.include"
				ScanSyncSystemIndexChanges --execute-sync "$CACHE_ROOT" "$TGT_PROCESS"
			)

			[ -z "$MDSC_DETAIL" ] || echo "< $MDSC_CMD: cache-output metadata cloned." >&2

			return 0
		;;
		--help|--help-syntax)
			echo "📘 syntax: DistroSourceProcess.fn.sh --ingest-distro-index-from-source" >&2
			echo "📘 syntax: DistroSourceProcess.fn.sh <option>" >&2
			# echo "📘 syntax: DistroSourceProcess.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				cat "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.DistroSourceProcess.text" >&2
			fi
			return 0
		;;
		*)
			echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
			set +e ; return 1
		;;
	esac
}

case "$0" in
	*/sh-scripts/DistroSourceProcess.fn.sh)
		set -e 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			DistroSourceProcess "${1:-"--help-syntax"}"
			exit 1
		fi
		
		DistroSourceProcess "$@"
	;;
esac
