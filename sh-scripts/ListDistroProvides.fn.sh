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

ListDistroProvides(){
	local MDSC_CMD='ListDistroProvides'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	case "$1" in
		--all-provides|--all-provides-merged|--add-*-column)
		;;
		--explicit-noop)
			shift
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "ERROR: $MDSC_CMD: --select-from-env no projects selected!" >&2
				set +e ; return 1
			fi
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
			ListDistroProjects --select-execute-default ListDistroProvides "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	local indexFile="$MDSC_CACHED/distro-index.inf"
	local indexAllProvides=""
	local indexOwnProvides=""
	local indexColumns=""

	while true ; do
		case "$1" in
			--all-provides)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-provides option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				##
				## check cache ready
				##
				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ ! -z "${MDSC_IDOPRV:0:1}" ] ; then
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDOPRV"
						return 0
					fi
					if [ ! -z "$MDSC_IDAPRV_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides using MDSC_IDAPRV_NAME (--all-provides-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDOPRV="` cat "$MDSC_IDAPRV_NAME" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDOPRV"
						return 0
					fi
					if [ ! -z "${MDSC_IDAPRV:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides using MDSC_IDAPRV (--all-provides-merged) ($MDSC_OPTION)" >&2
						export MDSC_IDOPRV="` echo "$MDSC_IDAPRV" | cut -d" " -f2,3 | awk '!x[$0]++' `"
						echo "$MDSC_IDOPRV"
						return 0
					fi
					if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-provides.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-provides caching projects ($MDSC_OPTION)" >&2
						ListDistroProvides --explicit-noop --no-cache --all-provides | tee "$cacheFile"
						return 0
					fi
				fi
	
				if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] && [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
						
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides using index" >&2
						
						local projectName extraText
						grep -e "^PRJ-PRV-" "$indexFile" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\:|:|g' \
						| while read -r projectName extraText ; do
							echo "$extraText" | tr ' ' '\n' | sed -e "s:^:$projectName :"
						done
						
						return 0
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDOPRV="` ListDistroProvides --explicit-noop --no-cache --all-provides `"
					echo "$MDSC_IDOPRV"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-provides extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					DistroSourceCommand \
						-q \
						--import-from-source \
						--select-all \
						--print-provides-separate-lines
						
					return 0
				fi
				
				echo "| $MDSC_CMD: --all-provides extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListAllRepositories
				Require ListRepositoryProvides
			
				local repositoryName
				ListAllRepositories | while read -r repositoryName ; do
					ListRepositoryProvides $repositoryName $useNoCache $useNoIndex || true
				done
	
				return 0
			;;
			--all-provides-merged)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: no options allowed after --all-provides-merged option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					if [ ! -z "$MDSC_IDAPRV_NAME" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides-merged using cache file ($MDSC_OPTION)" >&2
						cat "$MDSC_IDAPRV_NAME"
						return 0
					fi
					if [ ! -z "${MDSC_IDAPRV:0:1}" ] ; then 
						[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides-merged using env-cached ($MDSC_OPTION)" >&2
						echo "$MDSC_IDAPRV"
						return 0
					fi
					if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
						local cacheFile="$MDSC_CACHED/distro-merged-provides.txt"
						if [ -f "$cacheFile" ] && [ "$cacheFile" -nt "$indexFile" ] \
						&& ([ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ]) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides-merged using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						##
						## Build cache index file, no MDSC_IDxxx variables
						##
						echo "| $MDSC_CMD: --all-provides-merged caching projects ($MDSC_OPTION)" >&2
						ListDistroProvides --explicit-noop --no-cache --all-provides-merged | tee "$cacheFile"
						return 0
					fi
				fi

				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "deploy" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then

							[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides-merged using index ($MDSC_OPTION)" >&2

							local indexProvides="` \
								grep -e "^PRJ-PRV-" "$indexFile" | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\\\:|:|g' \
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

							join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexProvides" ) <( echo "$indexSequence" ) \
							| sort -n -k 1,2 | cut -d" " -f 3-
							
							return 0 # 2s
						fi
					fi
				fi

				if [ "$useNoCache" != "--no-cache" ] ; then
					[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: --all-provides-merged env-caching projects ($MDSC_OPTION)" >&2
					export MDSC_IDAPRV="` ListDistroProvides --explicit-noop --no-cache --all-provides-merged `"
					echo "$MDSC_IDAPRV"
					return 0
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "| $MDSC_CMD: --all-provides-merged extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					local indexProvides="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-provides-separate-lines \
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
					
					join -o 2.1,1.1,2.2,1.2,1.3 -12 -23 <( echo "$indexProvides" ) <( echo "$indexSequence" ) \
					| sort -n -k 1,2 | cut -d" " -f 3-
					
					return 0
				fi

				echo "| $MDSC_CMD: --all-provides-merged extracting from source (shell) ($MDSC_OPTION)" >&2

				Require ListDistroSequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence $useNoCache $useNoIndex --all ) ; do
					ListProjectProvides "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--add-own-provides-column|--filter-own-provides-column|--add-merged-provides-column|--filter-merged-provides-column)
				local lastOperation=${1%"-provides-column"} ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: $MDSC_CMD: $lastOperation project provides filter is expected!" >&2
					set +e ; return 1
				fi
				local columnMatcher="$1" ; shift
				if [ "--add-own" = "$lastOperation" ] || [ "--filter-own" = "$lastOperation" ] ; then
					if [ -z "${indexOwnProvides:0:1}" ] ; then
						local indexOwnProvides="` ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides `"
					fi
				else
					if [ -z "${indexAllProvides:0:1}" ] ; then
						local indexAllProvides="` ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides-merged `"
					fi
				fi
				
				
				local indexCurrent="` \
					if [ -z "${indexColumns:0:1}" ] ; then
						if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
							if [ "--add-own" = "lastOperation" ] || [ "--filter-own" = "lastOperation" ] ; then
								echo "$indexOwnProvides" | cut -d" " -f1
							else
								echo "$indexAllProvides" | cut -d" " -f1 | awk '!x[$0]++'
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
							echo "$indexOwnProvides" | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-own|*:--filter-own)
							echo "$indexOwnProvides" | grep -e "^\S* $columnMatcher$"
						;;
						*::--add-merged|*::--filter-merged)
							echo "$indexAllProvides" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher.*$" | sed -e "s| $columnMatcher| |"
						;;
						*:--add-merged|*:--filter-merged)
							echo "$indexAllProvides" | cut -d" " -f1,3 | grep -e "^\S* $columnMatcher$"
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
					echo "ERROR: $MDSC_CMD: project provides filter is expected!" >&2
					set +e ; return 1
				fi
				local filterProvides="$1" projectName projectProvides ; shift
				ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides \
				| while read -r projectName projectProvides ; do
				 	if [ "$projectProvides" != "${projectProvides#${filterProvides}:}" ] ; then
						echo "$projectName ${projectProvides#${filterProvides}:}"
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
				
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $MDSC_SELECT_PROJECTS ; do
					ListProjectProvides "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
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
				if [ ! -z "$indexColumns" ] ; then
					echo "$indexColumns"
					return 0
				fi
				
				if [ ! -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$MDSC_SELECT_PROJECTS" \
					) <( \
						ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides \
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
	*/sh-scripts/ListDistroProvides.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProvides.fn.sh --all-provides" >&2
			echo "syntax: ListDistroProvides.fn.sh --all-provides-merged" >&2
			echo "syntax: ListDistroProvides.fn.sh <project-selector> [--merge-sequence] [<options>]" >&2
			echo "syntax: ListDistroProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpListDistroProvides.include"
			fi
			exit 1
		fi
		
		ListDistroProvides "$@"
	;;
esac
