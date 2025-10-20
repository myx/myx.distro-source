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

DistroImagePrepare(){

	set -e

	local MDSC_CMD='DistroImagePrepare'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	case "$1" in
		--ingest-distro-image-from-git)
			shift
			return 1
		;;
		--ingest-distro-image-from-output)
			shift
			return 0
		;;
		--ingest-distro-index-from-processed)
			shift

			local CACHE_ROOT="$MMDAPP/.local/output-cache"
			local INDEX_ROOT="$MMDAPP/.local/system-index"
			mkdir -p "$INDEX_ROOT"

			local CACHE_DATE="$CACHE_ROOT/process-ingest.timestamp.txt"
			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: source cache timestamp expected: $CACHE_DATE" >&2
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
		--rebuild-cached-index)
			shift

			if [ -z "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 ; then
				[ -z "${ENV_DISTRO_SOURCE_JAVA-}" ] || ( echo "⛔ ERROR: DistroSourceCommand." >&2 && exit 1 )

				local indexFile="$MDSC_CACHED/distro-index.inf"
				local buildDate="$MDSC_CACHED/build-time-stamp.txt"
				#[ full != "$MDSC_DETAIL" ] || set -x

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
					echo "⛔ ERROR: $MDSC_CMD: distro-index.inf is expected!" >&2
					set +e ; return 1
				}
				
				touch -r "$indexFile" "$buildDate"
			else
				DistroImagePrepare.fn.sh --build-project-metadata
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
		--help|--help-syntax)
			echo "📘 syntax: DistroImagePrepare.fn.sh --ingest-distro-index-from-processed" >&2
			echo "📘 syntax: DistroImagePrepare.fn.sh <option>" >&2
			# echo "📘 syntax: DistroImagePrepare.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				cat "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.DistroImagePrepare.text" >&2
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
	*/sh-scripts/DistroImagePrepare.fn.sh)
		set -e 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			DistroImagePrepare "${1:-"--help-syntax"}"
			exit 1
		fi
		
		DistroImagePrepare "$@"
	;;
esac
