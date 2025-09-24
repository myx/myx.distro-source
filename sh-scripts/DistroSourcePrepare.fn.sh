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

type DistroSource >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/lib.distro-source.include"

DistroSourcePrepare(){

	local MDSC_CMD='DistroSourcePrepare'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

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
			return 0
		;;
		--ingest-distro-index-from-source)
			shift
			. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/SyncSourceCachedFromSource.include"

			local INDEX_ROOT="$MMDAPP/.local/source-cache/enhance"
			mkdir -p "$INDEX_ROOT"

			local NEW_CHANGED="$MMDAPP/.local/source-cache/new-changed.index.txt"
			if [ ! -s "$NEW_CHANGED" ]; then
				echo "> $MDSC_CMD IngetDistroIndexFromSource.include: 🫙 no changes." >&2
				return 0
			fi

			local NEW_CONTENT="$MMDAPP/.local/source-cache/new-content.index.txt"

			local ALL_CHANGED="$MMDAPP/.local/source-cache/all-changed.index.txt"
			local ALL_PROJECTS="$MMDAPP/.local/source-cache/all-projects.index.txt"
			local ALL_NAMESPACES="$MMDAPP/.local/source-cache/all-namespaces.index.txt"

			local INGEST_TIMESTAMP="$MMDAPP/.local/source-cache/source-ingest.timestamp.txt"

			cp -f "$INGEST_TIMESTAMP" "$INDEX_ROOT/build-time-stamp.txt"

			cat "$ALL_NAMESPACES" > "$INDEX_ROOT/distro-distro-namespaces.txt"
			cat "$ALL_PROJECTS" > "$INDEX_ROOT/all-project-names.txt" # <<< this is not needed and not used, sequence is better
			cat "$ALL_CHANGED" > "$INDEX_ROOT/changed-project-names.txt"
			return 0
		;;
		--rebuild-cached-index)
			shift
			[ -z "${ENV_DISTRO_SOURCE_JAVA-}" ] || ( echo "⛔ ERROR: DistroSourceCommand." >&2 && exit 1 )

			#[ "full" != "$MDSC_DETAIL" ] || set -x

			Distro DistroSourceCommand \
				-v$( 
					[ -z "$MDSC_DETAIL" ] || printf 'v' 
					[ "full" != "$MDSC_DETAIL" ] || printf 'v' 
				) \
				--no-fail \
				--import-from-source --select-all-from-source \
				--prepare-source-to-cached-index \
				--print '' \
				--fail-if-errors \

			return 0
		;;
		--build-project-metadata)
			shift
			local inf
			cat "$MMDAPP/.local/source-cache/all-projects.index.txt" \
			| while IFS= read -r inf; do
				(
					[ -z "$MDSC_DETAIL" ] || echo "| 📑 BuildSourceProjectMedatata.include: project: $inf" >&2
					inf="$MMDAPP/.local/source-cache/sources/$inf/project.inf"
					. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/source-prepare/ReadSourceProjectMetadata.include"
				)
			done
		;;
		--check-ensure-index)
			set +e ; return 1
		;;
		--rebuild-source-index)
			set +e ; return 1
		;;
		'')
			if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
					echo "$MDSC_SELECT_PROJECTS" \
				) <( \
					DistroSourcePrepare --explicit-noop $MDSC_NO_CACHE $MDSC_NO_INDEX --all-projects \
				)
				break
			fi

			echo "⛔ ERROR: $MDSC_CMD: no projects selected!" >&2
			set +e ; return 1
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
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: DistroSourcePrepare.fn.sh [<options>] --all-projects" >&2
			echo "📘 syntax: DistroSourcePrepare.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "📘 syntax: DistroSourcePrepare.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
				echo >&2
				echo "  Options:" >&2
				echo >&2
				echo "    --explicit-noop" >&2
				echo "                Explicit argument that safely does nothing." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --merge-sequence" >&2
				echo "                Include all inherited provides for each project selected." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "    DistroSourcePrepare.fn.sh --all-projects" >&2
				echo >&2
				echo ""
			fi
			exit 1
		fi
		
		DistroSourcePrepare "$@"
	;;
esac
