#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type DistroSource >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/lib.distro-source.include"
fi

ListDistroKeywords(){
	local MDSC_CMD='ListDistroKeywords'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	case "$1" in
		--all-keywords|--all-keywords-merged|--add-*-column)
		;;
		--explicit-noop)
			shift
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "⛔ ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--set-env)
			shift
			if [ -z "$1" ] ; then
				echo "⛔ ERROR: $MDSC_CMD: --set-env argument expected!" >&2
				set +e ; return 1
			fi
			local envName="$1" ; shift
			eval "$envName='` $MDSC_CMD --explicit-noop "$@" `'"
			return 0
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ListDistroKeywords "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllKeywords=""
	local indexOwnKeywords=""
	local indexColumns=""

	while true ; do
		case "$1" in
			--all-keywords)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-keywords option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				##
				## check cache ready
				##
				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ -n "${MDSC_IDOKWD:0:1}" ] ; then
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDOKWD"
						return 0
					fi
					if [ -n "$MDSC_IDAKWD_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords using MDSC_IDAKWD_NAME (--all-keywords-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDOKWD="` cat "$MDSC_IDAKWD_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDOKWD"
						return 0
					fi
					if [ -n "${MDSC_IDAKWD:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords using MDSC_IDAKWD (--all-keywords-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDOKWD="` echo "$MDSC_IDAKWD" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDOKWD"
						return 0
					fi
					if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-keywords.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-keywords caching projects ($MDSC_OPTION)" >&2
						ListDistroKeywords --explicit-noop --no-cache --all-keywords | tee "$cacheFile"
						return 0
					fi
				fi
	
				if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] && [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords using index" >&2
						
						local projectName extraText
						grep -e "^PRJ-KWD-" "$indexFile" | sort | sed -e 's:^PRJ-KWD-::' -e 's:=: :g' -e 's|\\:|:|g' \
						| while read -r projectName extraText ; do
							echo "$extraText" | tr ' ' '\n' | sed -e "s:^:$projectName :"
						done
						
						return 0
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDOKWD="` ListDistroKeywords --explicit-noop --no-cache --all-keywords `"
					echo "$MDSC_IDOKWD"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-keywords extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					DistroSourceCommand \
						-q \
						--import-from-source \
						--print-all-keywords-separate-lines

						# --select-all \
						# --print-keywords-separate-lines
						
					return 0
				fi
				
				echo "| $MDSC_CMD: --all-keywords extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListAllRepositories
				Require ListRepositoryKeywords
			
				local repositoryName
				ListAllRepositories | while read -r repositoryName ; do
					ListRepositoryKeywords $repositoryName $useNoCache $useNoIndex || true
				done
	
				return 0
			;;
			--all-keywords-merged)
				shift
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --all-keywords-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ -n "$MDSC_IDAKWD_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords-merged using cache file ($MDSC_OPTION)" >&2
						cat "$MDSC_IDAKWD_NAME"
						return 0
					fi
					if [ -n "${MDSC_IDAKWD:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords-merged using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDAKWD"
						return 0
					fi
					if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-merged-keywords.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords-merged using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-keywords-merged caching projects ($MDSC_OPTION)" >&2
						ListDistroKeywords --explicit-noop --no-cache --all-keywords-merged | tee "$cacheFile"
						return 0
					fi
				fi

				if [ -n "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then

							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords-merged using index ($MDSC_OPTION)" >&2

							local indexKeywords="` \
								grep -e "^PRJ-KWD-" "$indexFile" | sed -e 's:^PRJ-KWD-::' -e 's:=: :g' -e 's|\\\\:|:|g' \
								| while read -r projectName extraText ; do
									for extraText in $extraText ; do
										echo "$projectName" "$extraText"
									done
								done | cat -n | sort -k 2
							`"
							local indexSequence="` \
								grep -e "^PRJ-SEQ-" "$indexFile" | sed -e 's:^PRJ-SEQ-::' -e 's:=: :g' \
								| while read -r projectName extraText ; do
									for extraText in $extraText ; do
										echo "$projectName" "$extraText"
									done
								done | cat -n | sort -k 3
							`"

							join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexKeywords" ) <( echo "$indexSequence" ) \
							| sort -n -k 1,2 | cut -d" " -f 3-
							
							return 0 # 2s
						fi
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-keywords-merged env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDAKWD="` ListDistroKeywords --explicit-noop --no-cache --all-keywords-merged `"
					echo "$MDSC_IDAKWD"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-keywords-merged extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					local indexKeywords="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-keywords-separate-lines \
						| cat -n | sort -k 2
					`"

					local indexSequence="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-sequence-separate-lines \
						| cat -n | sort -k 3
					`"
					
					join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexKeywords" ) <( echo "$indexSequence" ) \
					| sort -n -k 1,2 | cut -d" " -f 3-
					
					return 0
				fi

				echo "| $MDSC_CMD: --all-keywords-merged extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListDistroSequence
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence $useNoCache $useNoIndex --all ) ; do
					ListProjectKeywords "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--add-own-keywords-column|--filter-own-keywords-column|--add-merged-keywords-column|--filter-merged-keywords-column)
				local lastOperation=${1%"-keywords-column"} ; shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local columnMatcher="$1" ; shift
				if [ "--add-own" = "$lastOperation" ] || [ "--filter-own" = "$lastOperation" ] ; then
					if [ -z "${indexOwnKeywords:0:1}" ] ; then
						local indexOwnKeywords="` ListDistroKeywords --explicit-noop $useNoCache $useNoIndex --all-keywords `"
					fi
				else
					if [ -z "${indexAllKeywords:0:1}" ] ; then
						local indexAllKeywords="` ListDistroKeywords --explicit-noop $useNoCache $useNoIndex --all-keywords-merged `"
					fi
				fi
				
				
				local indexCurrent="` \
					if [ -z "${indexColumns:0:1}" ] ; then
						if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
							if [ "--add-own" = "lastOperation" ] || [ "--filter-own" = "lastOperation" ] ; then
								echo "$indexOwnKeywords" | cut -d" " -f1
							else
								echo "$indexAllKeywords" | cut -d" " -f1 | awk '!x[$0]++'
							fi
						else
							echo "$MDSC_SELECT_PROJECTS"
						fi
					else
						echo "$indexColumns"
					fi \
					| cat -n \
					| sort -k 2 \
				`"
				
				local indexFiltered="` \
					case "$columnMatcher:$lastOperation" in
						*::--add-own|*::--filter-own)
							echo "$indexOwnKeywords" | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-own|*:--filter-own)
							echo "$indexOwnKeywords" | grep -e "^\S* $columnMatcher$"
						;;
						*::--add-merged|*::--filter-merged)
							echo "$indexAllKeywords" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-merged|*:--filter-merged)
							echo "$indexAllKeywords" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher$"
						;;
					esac \
					| awk '$0 && !x[$0]++' \
					| cat -n \
					| sort -k 2 \
				`"

				local tmpKey tmpInt1 tmpColumn tmpInt2 tmpColumns
				local indexColumns="` \
					case "$lastOperation" in
						--add-own|--add-merged)
							# join -e '-' -a 2 -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" )
							local indexVirtual="$( \
								( \
									echo "$indexFiltered" | tr '\t' ' ' | sed -E -e 's|^[ ]+||' ; \
									join -v 2 -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" ) | sed -e 's|$| -|' \
								) \
								| sort -k 2 \
							)"
							join -12 -22 <( echo "$indexVirtual" ) <( echo "$indexCurrent" )
						;;
						--filter-own|--filter-merged)
							join -12 -22 <( echo "$indexFiltered" ) <( echo "$indexCurrent" )
						;;
					esac \
					| sort -n -k 2,4 \
					| while read -r tmpKey tmpInt1 tmpColumn tmpInt2 tmpColumns ; do
						# | cut -d" " -f 1,5-,3
						echo $tmpKey $tmpColumns $tmpColumn
					done \
					| awk '$0 && !x[$0]++' \
				`"
				
				if [ -z "$indexColumns" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: $lastOperation no projects selected!" >&2
					set +e ; return 1
				fi
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: project keywords filter is expected!" >&2
					set +e ; return 1
				fi
				local filterKeywords="$1" projectName projectKeywords ; shift
				ListDistroKeywords --explicit-noop $useNoCache $useNoIndex --all-keywords \
				| while read -r projectName projectKeywords ; do
				 	if [ "$projectKeywords" != "${projectKeywords#${filterKeywords}:}" ] ; then
						echo "$projectName ${projectKeywords#${filterKeywords}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: --merge-sequence, no projects selected!" >&2
					set +e ; return 1
				fi
				
				Require ListProjectKeywords
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectKeywords "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			'')
				if [ -n "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ -n "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						ListDistroKeywords --explicit-noop $useNoCache $useNoIndex --all-keywords \
					)
					return 0
				fi

				echo "⛔ ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

}

case "$0" in
	*/sh-scripts/ListDistroKeywords.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroKeywords.fn.sh --all-keywords" >&2
			echo "syntax: ListDistroKeywords.fn.sh --all-keywords-merged" >&2
			echo "syntax: ListDistroKeywords.fn.sh <project-selector> [--merge-sequence]" >&2
			echo "syntax: ListDistroKeywords.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpListDistroKeywords.include"
			fi
			exit 1
		fi
		
		ListDistroKeywords "$@"
	;;
esac
