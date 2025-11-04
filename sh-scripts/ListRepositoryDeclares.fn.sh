#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

ListRepositoryDeclares(){
	
	local MDSC_CMD='ListRepositoryDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	local repositoryName="$1"
	if [ -z "$repositoryName" ] ; then
		echo "⛔ ERROR: ListRepositoryDeclares: 'repositoryName' argument is required!" >&2
		set +e ; return 1
	fi
	shift

	set -e

	case "$1" in
		--print-declares-only)
			shift
			ListRepositoryDeclares "$repositoryName" "$@" | awk '{print $2}'
			return 0
		;;
	esac

	while true ; do
		case "$1" in
			--filter-projects)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: ListRepositoryDeclares: project name filter is expected!" >&2
					set +e ; return 1
				fi
				local projectFilter="$1" ; shift
				ListRepositoryDeclares "$repositoryName" "$@" | grep -e "^.*$projectFilter.* "
				return 0
			;;
			--print-project)
				shift
				
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $( Distro ListRepositorySequence "$repositoryName" ) ; do
					ListProjectDeclares "$sequenceProjectName" "$@" | sed "s|^|$sequenceProjectName |g"
				done	
				return 0
			;;
			--merge-sequence)
				shift
				
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $( Distro ListRepositorySequence "$repositoryName" ) ; do
					ListProjectDeclares "$sequenceProjectName" --merge-sequence "$@"
				done	
				return 0
			;;
			--filter)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: ListRepositoryDeclares: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" ; shift

				local filterDeclares="$1" projectName projectDeclares ; shift
				ListRepositoryDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX "$repositoryName" "$@" \
				| while read -r projectName projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			'')
				break;
			;;
			*)
				echo "⛔ ERROR: ListRepositoryDeclares: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
		if [ "$MDSC_NO_CACHE" != "--no-cache" ] ; then
			local cacheFile="$MDSC_CACHED/$repositoryName/repository-declares.txt"
			local buildDate="$MDSC_CACHED/build-time-stamp.txt"
			if [ -f "$cacheFile" ] && [ -f "$buildDate" ] && [ ! "$cacheFile" -ot "$buildDate" ] ; then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryDeclares: using cached ($MDSC_OPTION)" >&2
				cat "$cacheFile"
				return 0
			fi

			echo "ListRepositoryDeclares: caching projects ($MDSC_OPTION)" >&2
			mkdir -p "$MDSC_CACHED/$repositoryName"
			ListRepositoryDeclares --no-cache $repositoryName | tee "$cacheFile.$$.tmp"
			mv -f "$cacheFile.$$.tmp" "$cacheFile" || :
			return 0
		fi
		
		if [ "$MDSC_NO_INDEX" != "--no-index" ] ; then
			local indexFile="$MDSC_CACHED/$repositoryName/repository-index.env.inf"
			if [ -f "$indexFile" ] && \
				( [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ ! "$BUILD_STAMP" -gt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
			then
				[ -z "$MDSC_DETAIL" ] || echo "| ListRepositoryDeclares: using index ($MDSC_OPTION)" >&2
				local MTC="^PRJ-DCL-$repositoryName/"
				
				grep "$MTC" "$indexFile" \
				| sed -e 's:^PRJ-DCL-::' -e 's:=: :g' -e 's|\\:|:|g' \
				| awk '{ for (i=2;i<=NF;i++) print $1, $i }'
			
				return 0
			fi
		fi
	fi
	
	if [ javac = "$MDSC_JAVAC" ] && command -v javac >/dev/null 2>&1 && [ "$MDSC_INMODE" = "source" ] && [ -f "$MMDAPP/.local/roots/$repositoryName.distro-namespace" ] ; then
		echo "ListRepositoryDeclares: extracting from source (java) ($MDSC_OPTION)" >&2

		Distro DistroSourceCommand \
			-q \
			--import-from-source \
			--select-repository "$repositoryName" \
			--print-declares-separate-lines
			
		return 0
	fi
	
	Require ListProjectDeclares

	local projectName
	Distro ListRepositoryProjects "$repositoryName" | while read -r projectName ; do
		ListProjectDeclares $MDSC_NO_CACHE $MDSC_NO_INDEX $projectName "$@" || :
	done
}

case "$0" in
	*/sh-scripts/ListRepositoryDeclares.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ListRepositoryDeclares.fn.sh <repository_name> [--print-declares-only] [<search>] [--no-cache] [--filter filter_by]" >&2
			echo "📘 syntax: ListRepositoryDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo >&2
				echo "    --all / --filter-projects <glob> / --filter <declares-filter>" >&2
				echo >&2
				echo "  Options:" >&2
				echo >&2
				echo "    --no-cache" >&2
				echo "                Use no cache." >&2
				echo >&2
				echo "    --no-index" >&2
				echo "                Use no index." >&2
				echo >&2
				echo "  Examples:" >&2
				echo >&2
				echo "    ListRepositoryDeclares.fn.sh --distro-from-source myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh --distro-from-cached myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh --distro-source-only myx 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh myx --filter-projects macosx 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh myx --filter-projects clean | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh prv --filter-projects myx --filter-projects l6b2 --no-cache --no-index | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh prv --filter deploy-ssh-target 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh prv --filter image-execute:deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh --distro-source-only prv --filter image-execute:deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListRepositoryDeclares.fn.sh ndm --print-project --merge-sequence --filter deploy-keyword" >&2
			fi
			exit 1
		fi
		
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
			DistroSystemContext --distro-path-auto
		fi

		ListRepositoryDeclares "$@"
	;;
esac
