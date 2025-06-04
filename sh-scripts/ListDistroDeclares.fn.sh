#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type DistroSource >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/lib.distro-source.include"
fi

ListDistroDeclares(){
	local MDSC_CMD='ListDistroDeclares'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
			--all-*|--add-*-column)
				break
			;;
			--explicit-noop)
				shift
			;;
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			--select-from-env)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
					set +e ; return 1
				fi
				break
			;;
			--set-env)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: --set-env argument expected!" >&2
					set +e ; return 1
				fi
				local envName="$1" ; shift
				eval "$envName='` $MDSC_CMD --explicit-noop "$@" `'"
				return 0
			;;
			--*)
				Require ListDistroProjects
				ListDistroProjects --select-execute-default ListDistroDeclares "$@"
				return 0
			;;
		esac
	done

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllDeclares=""
	local indexOwnDeclares=""
	local indexColumns=""

	while true ; do
		case "$1" in
			--all-declares)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-declares option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				##
				## check cache ready
				##
				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ ! -z "${MDSC_IDODCL:0:1}" ] ; then
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDODCL"
						return 0
					fi
					if [ ! -z "$MDSC_IDADCL_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares using MDSC_IDADCL_NAME (--all-declares-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDODCL="` cat "$MDSC_IDADCL_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDODCL"
						return 0
					fi
					if [ ! -z "${MDSC_IDADCL:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares using MDSC_IDADCL (--all-declares-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDODCL="` echo "$MDSC_IDADCL" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDODCL"
						return 0
					fi
					if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-declares.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-declares caching projects ($MDSC_OPTION)" >&2
						ListDistroDeclares --explicit-noop --no-cache --all-declares | tee "$cacheFile"
						return 0
					fi
				fi
	
				if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] && [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares using index" >&2
						
						local projectName extraText
						grep -e "^PRJ-DCL-" "$indexFile" | sort | sed -e 's:^PRJ-DCL-::' -e 's:=: :g' -e 's|\\:|:|g' \
						| while read -r projectName extraText ; do
							echo "$extraText" | tr ' ' '\n' | sed -e "s:^:$projectName :"
						done
						
						return 0
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDODCL="` ListDistroDeclares --explicit-noop --no-cache --all-declares `"
					echo "$MDSC_IDODCL"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-declares extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					DistroSourceCommand \
						-q \
						--import-from-source \
						--select-all \
						--print-declares-separate-lines
						
					return 0
				fi
				
				echo "| $MDSC_CMD: --all-declares extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListAllRepositories
				Require ListRepositoryDeclares
			
				local repositoryName
				ListAllRepositories | while read -r repositoryName ; do
					ListRepositoryDeclares $repositoryName $useNoCache $useNoIndex || true
				done
	
				return 0
			;;
			--all-declares-prefix-cut) # from: --filter-and-cut
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" projectName projectDeclares ; shift
				ListDistroDeclares --explicit-noop $useNoCache $useNoIndex --all-declares \
				| while read -r projectName projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--all-declares-merged)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-declares-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ ! -z "$MDSC_IDADCL_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares-merged using cache file ($MDSC_OPTION)" >&2
						cat "$MDSC_IDADCL_NAME"
						return 0
					fi
					if [ ! -z "${MDSC_IDADCL:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares-merged using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDADCL"
						return 0
					fi
					if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-merged-declares.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares-merged using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-declares-merged caching projects ($MDSC_OPTION)" >&2
						ListDistroDeclares --explicit-noop --no-cache --all-declares-merged | tee "$cacheFile"
						return 0
					fi
				fi

				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then

							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares-merged using index ($MDSC_OPTION)" >&2

							local indexDeclares="` \
								grep -e "^PRJ-DCL-" "$indexFile" | sed -e 's:^PRJ-DCL-::' -e 's:=: :g' -e 's|\\\\:|:|g' \
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

							join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexDeclares" ) <( echo "$indexSequence" ) \
							| sort -n -k 1,2 | cut -d" " -f 3-
							
							return 0 # 2s
						fi
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-declares-merged env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDADCL="` ListDistroDeclares --explicit-noop --no-cache --all-declares-merged `"
					echo "$MDSC_IDADCL"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-declares-merged extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					local indexDeclares="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-declares-separate-lines \
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
					
					join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexDeclares" ) <( echo "$indexSequence" ) \
					| sort -n -k 1,2 | cut -d" " -f 3-
					
					return 0
				fi

				echo "| $MDSC_CMD: --all-declares-merged extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListDistroSequence
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence $useNoCache $useNoIndex --all ) ; do
					ListProjectDeclares "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--add-own-declares-column|--filter-own-declares-column|--add-merged-declares-column|--filter-merged-declares-column)
				local lastOperation=${1%"-declares-column"} ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: $lastOperation project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local columnMatcher="$1" ; shift
				if [ "--add-own" = "$lastOperation" ] || [ "--filter-own" = "$lastOperation" ] ; then
					if [ -z "${indexOwnDeclares:0:1}" ] ; then
						local indexOwnDeclares="` ListDistroDeclares --explicit-noop $useNoCache $useNoIndex --all-declares `"
					fi
				else
					if [ -z "${indexAllDeclares:0:1}" ] ; then
						local indexAllDeclares="` ListDistroDeclares --explicit-noop $useNoCache $useNoIndex --all-declares-merged `"
					fi
				fi
				
				
				local indexCurrent="` \
					if [ -z "${indexColumns:0:1}" ] ; then
						if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
							if [ "--add-own" = "lastOperation" ] || [ "--filter-own" = "lastOperation" ] ; then
								echo "$indexOwnDeclares" | cut -d" " -f1
							else
								echo "$indexAllDeclares" | cut -d" " -f1 | awk '!x[$0]++'
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
							echo "$indexOwnDeclares" | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-own|*:--filter-own)
							echo "$indexOwnDeclares" | grep -e "^\S* $columnMatcher$"
						;;
						*::--add-merged|*::--filter-merged)
							echo "$indexAllDeclares" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-merged|*:--filter-merged)
							echo "$indexAllDeclares" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher$"
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
					echo "ERROR: $MDSC_CMD: $lastOperation no projects selected!" >&2
					set +e ; return 1
				fi
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: project declares filter is expected!" >&2
					set +e ; return 1
				fi
				local filterDeclares="$1" projectName projectDeclares ; shift
				ListDistroDeclares --explicit-noop $useNoCache $useNoIndex --all-declares \
				| while read -r projectName projectDeclares ; do
				 	if [ "$projectDeclares" != "${projectDeclares#${filterDeclares}:}" ] ; then
						echo "$projectName ${projectDeclares#${filterDeclares}:}"
					fi
				done | awk '!x[$0]++'
				return 0
			;;
			--merge-sequence)
				shift
				if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					echo "ERROR: $MDSC_CMD: --merge-sequence, no projects selected!" >&2
					set +e ; return 1
				fi
				
				Require ListProjectDeclares
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectDeclares "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			'')
				if [ ! -z "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ ! -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						ListDistroDeclares --explicit-noop $useNoCache $useNoIndex --all-declares \
					)
					return 0
				fi

				echo "ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			;;
			*)
				echo "ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

}

case "$0" in
	*/sh-scripts/ListDistroDeclares.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroDeclares.fn.sh [<options>] --all-declares" >&2
			# echo "syntax: ListDistroDeclares.fn.sh [<options>] --all-declares-merged" >&2
			echo "syntax: ListDistroDeclares.fn.sh [<options>] <project-selector> [--merge-sequence]" >&2
			echo "syntax: ListDistroDeclares.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpListDistroDeclares.include"
			fi
			exit 1
		fi
		
		ListDistroDeclares "$@"
	;;
esac
