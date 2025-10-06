#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectBuilders(){

	local MDSC_CMD='ListProjectBuilders'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	local projectName="${1#$MDSC_SOURCE/}"
	case "$projectName" in
	'')
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	;;
	--project-from-env)
		projectName="$MDSC_PRJ_NAME" ; [ -n "$projectName" ] || {
			echo "⛔ ERROR: $MDSC_CMD: --project-from-env: MDSC_PRJ_NAME is not set!" >&2
			set +e ; return 1
		}
	;;
	'.'|--project-from-pwd)
		projectName="$( Distro ListDistroProjects --project '.' )" ; [ -n "$projectName" ] || {
			echo "⛔ ERROR: $MDSC_CMD: --project-from-pwd: can't map working directory to project: $(pwd)" >&2
			set +e ; return 1
		}
	;;
	esac
	[ -f "$MDSC_SOURCE/$projectName/project.inf" ] || {
		echo "⛔ ERROR: $MDSC_CMD: project is invalid or unknown: $projectName" >&2
		set +e ; return 1
	}
	shift

	local printBuildStage
	case "$1" in
		--print-build-stage)
			shift
			local printBuildStage="--print-build-stage"
		;;
		*)
		;;
	esac

	local stageType="$1"

	case "$stageType" in
		--all-build-stages)
			set -e

			for stageType in source-prepare source-process image-prepare image-process image-install ; do
				ListProjectBuilders "$projectName" --print-build-stage "$stageType" "$2"
			done
			return 0
		;;
		source-prepare|source-process|image-prepare|image-process|image-install)
			set -e

			local buildersPath="$MMDAPP/source/$projectName/$stageType/builders"
			[ -d "$buildersPath" ] || return 0
			### only 1xxx - source-prepare, source-to-cached by default
			local stageFilter="${3#--}"
			local stagePrefix=""
			if [ "$printBuildStage" == "--print-build-stage" ] ; then
				stagePrefix="$stageType "
			fi
			for LINE in $( \
				find "$buildersPath" -mindepth 1 -type f -name $( \
					[ -z "$stageFilter" ] && echo "????-*.sh" || echo "$stageFilter???-*.sh" \
				) | sort \
			) ; do
				echo "$stagePrefix${LINE#$MMDAPP/source/}"
			done
		;;
		'')
			echo "⛔ ERROR: $MDSC_CMD: no build-stage selected!" >&2
			set +e ; return 1
		;;
		*)
			echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
			set +e ; return 1
		;;
	esac
}

case "$0" in
	*/sh-scripts/ListProjectBuilders.fn.sh)
		if [ -z "$1" ] || [ "$1"="--help" ] ; then
			echo "📘 syntax: ListProjectBuilders.fn.sh <project> [--print-build-stage] <build-stage>" >&2
			echo "📘 syntax: ListProjectBuilders.fn.sh <project> --all-build-stages" >&2
			echo "📘 syntax: ListProjectBuilders.fn.sh [--help]" >&2
			if [ "$1"="--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectStage.include"
				echo >&2
				echo "  Arguments:" >&2
				echo >&2
				echo "    --all-build-stages" >&2
				echo "                Output builders for all known build stages. Two columns." >&2
				echo >&2
				echo "    --print-build-stage" >&2
				echo "                Prints build stage in first column. Two columns." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "    ListProjectBuilders.fn.sh --distro-from-source myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "    ListProjectBuilders.fn.sh --distro-source-only myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "    ListProjectBuilders.fn.sh --distro-from-cached myx/myx.distro-source source-prepare 2> /dev/null" >&2
				echo "    ListProjectBuilders.fn.sh myx/myx.distro-source source-prepare" >&2
				echo "    ListProjectBuilders.fn.sh myx/myx.distro-source source-process" >&2
				echo "    ListProjectBuilders.fn.sh myx/myx.distro-source image-prepare" >&2
			fi
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectBuilders "$@"
	;;
esac
