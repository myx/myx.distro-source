#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-from-source
fi

Require ListDistroProjects
Require ListProjectBuilders

ListDistroBuilders(){
	local MDSC_CMD='ListDistroBuilders'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	local printBuildStage
	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--print-build-stage)
				shift
				local printBuildStage="--print-build-stage"
			;;
			*)
			;;
		esac
		break
	done

	local stageType="$1"
	if [ -z "$1" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'stageType' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	case "$stageType" in
		--all-build-stages|source-prepare|source-process|image-prepare|image-process|image-install)
			set -e

			local projectName
			local builderName

			if [ "$printBuildStage" == "--print-build-stage" ] || [ "$stageType" == "--all-build-stages" ] ; then
				local buildStage
				for projectName in $( . "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListAllProjects.include" ) ; do
					ListProjectBuilders "$projectName" $printBuildStage "$stageType" "$@" | while read -r buildStage builderName ; do
						echo "$buildStage" "$builderName" "` basename "$builderName" `" 
					done
				done | sort -k3 | cut -d" " -f1,2 \
				| awk '{
					b=$2; sub(".*/","",b)
					if (!seen[b]++) {
						print
					}
				}'
				return 0
			fi

			for projectName in $( . "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/system-context/DistroSystemListAllProjects.include" ) ; do
				ListProjectBuilders "$projectName" "$stageType" "$@" | while read -r builderName ; do
					echo "$builderName" "` basename "$builderName" `" 
				done
			done | sort -k2 | cut -d" " -f1 \
			| awk '{
				b=$1; sub(".*/","",b)
				if (!seen[b]++) {
					print
				}
			}'

			return 0
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
	*/sh-scripts/ListDistroBuilders.fn.sh) 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListDistroBuilders.fn.sh [--print-build-stage] <build-stage>" >&2
			echo "📘 syntax: ListDistroBuilders.fn.sh --all-build-stages" >&2
			echo "📘 syntax: ListDistroBuilders.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
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
				echo "    ListDistroBuilders.fn.sh --distro-from-source source-prepare 2> /dev/null | sort" >&2
				echo "    ListDistroBuilders.fn.sh --distro-from-cached source-prepare | sort" >&2
				echo "    ListDistroBuilders.fn.sh --distro-source-only source-prepare | sort" >&2
				echo "    ListDistroBuilders.fn.sh source-prepare --1" >&2
				echo "    ListDistroBuilders.fn.sh source-process --2" >&2
				echo "    ListDistroBuilders.fn.sh image-prepare --3" >&2
				echo "    ListDistroBuilders.fn.sh image-process --4" >&2
				echo "    ListDistroBuilders.fn.sh image-install --5" >&2
			fi
			exit 1
		fi
		
		ListDistroBuilders "$@"
	;;
esac
