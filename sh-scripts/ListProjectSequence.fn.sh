#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListProjectSequence(){

	local MDSC_CMD='ListProjectSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	local projectName=
	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptionsRequireProject.include" || return $?

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--print-project)
				shift
				
				ListProjectSequence "$projectName" "$@" | sed "s|^|$projectName |g"
				return 0
			;;
			--print-declares|--print-keywords|--print-provides)
				[ -z "$2" ] || {
					echo "⛔ ERROR: $MDSC_CMD: $1, no extra options allowed:" "$@" >&2
					set +e ; return 1
				}
				local idx="${1#'--print-'}"; shift
				
				if [ -n "$MDSC_CACHED" ]; then
					if [ "$MDSC_NO_CACHE" != "--no-cache" ]; then
					
						local cacheFile="$MDSC_CACHED/$projectName/project-${idx}-sequence.txt"
						local buildDate="$MDSC_CACHED/build-time-stamp.txt"
						if [ -f "$buildDate" ]; then
							if [ -f "$cacheFile" ] && [ ! "$cacheFile" -ot "$buildDate" ]; then
								[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: --print-* using cached, ${idx} ($MDSC_OPTION)" >&2
								cat "$cacheFile"
								return 0
							fi
				
							echo "$MDSC_CMD: $projectName: --print-* caching projects, ${idx} ($MDSC_OPTION)" >&2
							DistroSystemContext --index-${idx}-merged awk -v p="$projectName" '
								$1==p && !x[$3]++ { print $2, $3; }
							' | tee "$cacheFile.$$.tmp"
							mv -f "$cacheFile.$$.tmp" "$cacheFile" || :

							return 0
						fi

					fi
				fi			
				
				DistroSystemContext --index-${idx}-merged awk -v p="$projectName" '
					$1==p && !x[$3]++ { print $2, $3; }
				'
		
				return 0
			;;
			'')
				break;
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done


	if [ "$MDSC_NO_CACHE" != "--no-cache" ] && [ -d "$MDSC_CACHED" ] ; then
		local cacheFile="$MDSC_CACHED/$projectName/project-sequence.txt"
		local buildDate="$MDSC_CACHED/build-time-stamp.txt"
		if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: $projectName: using cached ($MDSC_OPTION)" >&2
			cat "$cacheFile"
			return 0
		fi

		if [ ! -d "$MDSC_CACHED/$projectName" ] ; then
			echo "$MDSC_CMD: $projectName: bypass ($MDSC_OPTION)" >&2
			ListProjectSequence --no-cache "$projectName"
			return 0
		fi

		echo "$MDSC_CMD: $projectName: caching projects ($MDSC_OPTION)" >&2
		ListProjectSequence --no-cache "$projectName" | tee "$cacheFile"
		return 0
	fi

	local indexFile="$MDSC_CACHED/$projectName/project-index.inf"

	if [ "$MDSC_NO_INDEX" != "--no-index" ] && [ -n "$MDSC_CACHED" ] && [ -f "$indexFile" ] ; then
		if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ ! "$BUILD_STAMP" -gt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
			echo "$MDSC_CMD: $projectName: using index ($MDSC_OPTION)" >&2
			
			local FILTER="$1"
			local currentProject
			if [ -z "$FILTER" ] ; then
				for currentProject in ` grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed 's|^.*=||g' ` ; do
					echo $currentProject
				done
			else
				for currentProject in ` grep "^PRJ-SEQ-$projectName=" "$indexFile" | sed 's|^.*=||g' ` ; do
					if [ "$currentProject" != "${currentProject#${FILTER}:}" ] ; then
						echo ${currentProject#${FILTER}:} | tr "|" "\n"
					fi
				done
			fi
			return 0
		fi
	fi
	
	if [ ! -f "$MDSC_SOURCE/$projectName/project.inf" ]; then
		echo "⛔ ERROR: $MDSC_CMD: $projectName: project.inf file is required (at: $indexFile)" >&2
		set +e ; return 1
	fi
	
	if [ -z "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ "$MDSC_INMODE" = "source" ] && [ -f "$MDSC_SOURCE/$projectName/project.inf" ] ; then
		echo "$MDSC_CMD: $projectName: extracting from source (java) ($MDSC_OPTION)" >&2

		Require DistroSourceCommand
		
		DistroSourceCommand \
			-q \
			--import-from-source \
			--select-project "$projectName" \
			--select-required \
			--print-sequence
		return 0
	fi
	
	echo "⛔ ERROR: $MDSC_CMD: $projectName: can't produce index, needs build." >&2
	set +e ; return 1
}

case "$0" in
	*/sh-scripts/ListProjectSequence.fn.sh) 
		# ListProjectSequence.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectSequence.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		# ListProjectSequence.fn.sh ndm/cloud.knt/setup.host-ndss111r3.ndm9.xyz
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListProjectSequence.fn.sh [--no-cache] <project_name> [--print-project] [--print-provides]" >&2
			echo "📘 syntax: ListProjectSequence.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project" >&2
				echo "    ListProjectSequence.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-provides" >&2
			fi
			exit 1
		fi

		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListProjectSequence "$@"
	;;
esac
