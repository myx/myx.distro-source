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

DistroSourcePrepare(){

	local MDSC_CMD='DistroSourcePrepare'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	set -e

	case "$1" in
		--scan-source-projects)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceProjects.include"
			return 0
		;;
		--scan-source-namespaces)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceNamespaces.include"
			return 0
		;;
		--scan-source-changes)
			shift
			{
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceNamespaces.include" \
				| while IFS= read -r repositoryName; do
					printf '%s/repository.inf\n' "$repositoryName"
				done

				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSourceProjects.include"
			} \
			| . "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ScanSyncSourceChanges.include"
			return 0
		;;
		--sync-cached-from-source)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/SyncSourceCachedFromSource.include"

			local CACHE_ROOT="$MMDAPP/.local/source-cache"

			local NEW_CHANGED="$CACHE_ROOT/new-changed.index.txt"
			if [ ! -s "$NEW_CHANGED" ]; then
				echo "< $MDSC_CMD IngestCacheFromSource.include: 🫙 no new changes." >&2
				return 0
			fi

			local CACHE_DATE="$CACHE_ROOT/prepare-ingest.timestamp.txt"

			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: source cache timestamp expected: $CACHE_DATE" >&2
				set +e ; return 1
			}

			local BUILT_ROOT="$CACHE_ROOT/prepare"; mkdir -p "$BUILT_ROOT"

			date -u "+%Y%m%d%H%M%S" > "$CACHE_ROOT/prepare-output.timestamp.txt"
			cp -f "$CACHE_DATE" "$BUILT_ROOT/build-time-stamp.txt"

			local ALL_CHANGED="$CACHE_ROOT/all-changed.index.txt"
			local ALL_PROJECTS="$CACHE_ROOT/all-projects.index.txt"
			local ALL_NAMESPACES="$CACHE_ROOT/all-namespaces.index.txt"

			cat "$ALL_NAMESPACES" > "$BUILT_ROOT/distro-namespaces.txt"
			cat "$ALL_PROJECTS" > "$BUILT_ROOT/distro-projects.txt" # <<< this is not needed and not used, sequence is better
			cat "$ALL_CHANGED" > "$BUILT_ROOT/changed-project-names.txt"

			return 0
		;;
		--ingest-distro-index-from-prepared)
			shift

			local CACHE_ROOT="$MMDAPP/.local/source-cache"
			local INDEX_ROOT="$MMDAPP/.local/system-index"
			mkdir -p "$INDEX_ROOT"

			local CACHE_DATE="$CACHE_ROOT/prepare-ingest.timestamp.txt"
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
				ScanSyncSystemIndexChanges --execute-sync "$CACHE_ROOT/prepare" "$INDEX_ROOT" || exit 1
			)

			DistroSystemContext --uncache-index
			[ -z "$MDSC_DETAIL" ] || echo "< $MDSC_CMD: system-index published." >&2

			return 0
		;;
		--ingest-distro-index-from-source)
			shift
			DistroSourcePrepare --sync-cached-from-source
			DistroSourcePrepare --ingest-distro-index-from-prepared
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
				DistroSourcePrepare.fn.sh --build-project-metadata
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
		--build-project-metadata)
			shift
			type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"
			type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
			local TGT_PREPARE="$MMDAPP/.local/source-cache/prepare"

			local CACHE_ROOT="$MMDAPP/.local/source-cache"
			local CACHE_DATE="$CACHE_ROOT/prepare-ingest.timestamp.txt"

			[ -f "$CACHE_DATE" ] || {
				echo "⛔ ERROR: $MDSC_CMD: source cache timestamp expected: $CACHE_DATE" >&2
				set +e ; return 1
			}

			mkdir -p "$TGT_PREPARE"

			(
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ParseSourceProjectInfMetadata.fn.include"
				Parallel ParseSourceProjectInfMetadata "$MMDAPP/.local/source-cache/sources" "$TGT_PREPARE"
				# Parallel Prefix -4 ParseSourceProjectInfMetadata "$MMDAPP/.local/source-cache/sources" "$TGT_PREPARE"
			) < "$MMDAPP/.local/source-cache/all-projects.index.txt" \
			| (
				local TMP_SUFFIX="$$.tmp"
				local NEW_INDEX="$MMDAPP/.local/source-cache/prepare/distro"
				local ALL_DECLARES="$TGT_PREPARE/distro-declares.txt"
				local ALL_KEYWORDS="$TGT_PREPARE/distro-keywords.txt"
				local ALL_PROVIDES="$TGT_PREPARE/distro-provides.txt"
				local ALL_REQUIRES="$TGT_PREPARE/distro-requires.txt"
				touch "$ALL_DECLARES.$TMP_SUFFIX" "$ALL_KEYWORDS.$TMP_SUFFIX" "$ALL_PROVIDES.$TMP_SUFFIX" "$ALL_REQUIRES.$TMP_SUFFIX"
				local projectName
				while IFS= read -r projectName; do
					[ full != "$MDSC_DETAIL" ] || echo "| 📑 CollectDistoMetadataFromProjects.include: project: $projectName" >&2
					cat "$TGT_PREPARE/$projectName/project-declares.txt" >> "$ALL_DECLARES.$TMP_SUFFIX"
					cat "$TGT_PREPARE/$projectName/project-keywords.txt" >> "$ALL_KEYWORDS.$TMP_SUFFIX"
					cat "$TGT_PREPARE/$projectName/project-provides.txt" >> "$ALL_PROVIDES.$TMP_SUFFIX"
					cat "$TGT_PREPARE/$projectName/project-requires.txt" >> "$ALL_REQUIRES.$TMP_SUFFIX"
					# ( echo "BUILD" "$MMDAPP/.local/source-cache/sources" "$MMDAPP/.local/source-cache/prepare" "$projectName" )
				done
				mv -f "$ALL_DECLARES.$TMP_SUFFIX" "$ALL_DECLARES"
				mv -f "$ALL_KEYWORDS.$TMP_SUFFIX" "$ALL_KEYWORDS"
				mv -f "$ALL_PROVIDES.$TMP_SUFFIX" "$ALL_PROVIDES"
				mv -f "$ALL_REQUIRES.$TMP_SUFFIX" "$ALL_REQUIRES"

				awk -f "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/BuildSequencesFromProvidesAndRequires.awk" \
					"$ALL_REQUIRES" "$ALL_PROVIDES" > "$TGT_PREPARE/distro-sequence-merged.txt"
			)

			return 0
		;;
		--help|--help-syntax)
			echo "📘 syntax: DistroSourcePrepare.fn.sh --ingest-distro-index-from-source" >&2
			echo "📘 syntax: DistroSourcePrepare.fn.sh <option>" >&2
			# echo "📘 syntax: DistroSourcePrepare.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				cat "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.DistroSourcePrepare.text" >&2
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
	*/sh-scripts/DistroSourcePrepare.fn.sh)
		set -e 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			DistroSourcePrepare "${1:-"--help-syntax"}"
			exit 1
		fi
		
		DistroSourcePrepare "$@"
	;;
esac
