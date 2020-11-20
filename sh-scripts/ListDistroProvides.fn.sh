#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && return 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ListDistroProvides(){
	
	[ -z "$MDSC_DETAIL" ] || echo ">>> ListDistroProvides $@" >&2

	set -e

	local projectsSelected=""
	
	case "$1" in
		--internal-print-project-provides-filter)
			# <filter> <project> <provide> [<provide>...]
			shift
			local FILTER="$1" ; shift
			local projectName="$1" ; shift
			local ITEM="$@"
		 	if [ "$ITEM" != "${ITEM#${FILTER}:}" ] ; then
				echo "$projectName ${ITEM#${FILTER}:}"
			fi
			return 0
		;;
		--print-provides-only)
			shift
			ListDistroProvides "$@" | awk '{print $2}' | awk '!x[$0]++'
			return 0
		;;
		--all-provides|--all-provides-merged|--add-*-column)
		;;
		--explicit-noop)
			shift
		;;
		--select-from-env)
			shift
			local projectsSelected="$MMDENVSELECTION"
			if [ -z "$projectsSelected" ] ; then
				echo "ERROR: ListDistroProvides: --select-from-env no projects selected!" >&2
				return 1
			fi
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
					echo "ListDistroProvides: no options allowed after --all-provides option ($MDSC_OPTION, $@)" >&2
					return 1
				fi
	
				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoCache" != "--no-cache" ] ; then
						local cacheFile="$MDSC_CACHED/distro-provides.txt"
						
						if [ -f "$cacheFile" ] && \
							( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] )
						then
							[ -z "$MDSC_DETAIL" ] || echo "ListDistroProvides: --all-provides using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
			
						echo "ListDistroProvides: --all-provides caching projects ($MDSC_OPTION)" >&2
						ListDistroProvides --explicit-noop --no-cache --all-provides > "$cacheFile"
						cat "$cacheFile"
						return 0
					fi
			
					if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
							
							echo "ListDistroProvides: --all-provides using index ($MDSC_OPTION)" >&2
							
							local projectName
							local extraText
							grep -e "^PRJ-PRV-" "$indexFile" | sort | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\:|:|g' | while read -r projectName extraText ; do
								echo "$extraText" | tr ' ' '\n' | sed -e "s:^:$projectName :"
							done
							
							return 0
						fi
					fi
				fi
				
				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "ListDistroProvides: --all-provides extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					DistroSourceCommand \
						-q \
						--import-from-source \
						--select-all \
						--print-provides-separate-lines
						
					return 0
				fi
				
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
					echo "ListDistroProvides: no options allowed after --all-provides-merged option ($MDSC_OPTION, $@)" >&2
					return 1
				fi
	
				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoIndex" != "--no-index" ] && [ -f "$indexFile" ] ; then
						if [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] ; then
							
							echo "ListDistroProvides: --all-provides-merged using index ($MDSC_OPTION)" >&2

							local indexProvides="` \
								grep -e "^PRJ-PRV-" "$indexFile" | sed -e 's:^PRJ-PRV-::' -e 's:=: :g' -e 's|\\\\:|:|g' \
							`"
							local indexSequence="` \
								grep -e "^PRJ-SEQ-" "$indexFile" | sed -e 's:^PRJ-SEQ-::' -e 's:=: :g' \
							`"
							
							join -o 2.1,1.1,1.2 -1 1 -2 2 <( \
								echo "$indexProvides" | while read -r projectName extraText ; do
									for extraText in $extraText ; do
										echo "$projectName" "$extraText"
									done
								done | sort -k 1
							) <( \
								echo "$indexSequence" | while read -r projectName extraText ; do
									for extraText in $extraText ; do
										echo "$projectName" "$extraText"
									done
								done | sort -k 2
							) | sort
							return 0 # 2s
						fi
					fi
				fi

				if [ "$MDSC_INMODE" = "source" ] ; then
					echo "ListDistroProvides: --all-provides-merged extracting from source (java) ($MDSC_OPTION)" >&2
			
					Require DistroSourceCommand
					
					local indexProvides="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-provides-separate-lines \
						| sort -k 1
					`"

					local indexSequence="` \
						DistroSourceCommand \
							-q \
							--import-from-source \
							--select-all \
							--print-sequence-separate-lines \
						| sort -k 2
					`"
					
					join -o 2.1,1.1,1.2 -1 1 -2 2 <( echo "$indexProvides" ) <( echo "$indexSequence" ) | sort
					return 0
				fi

				Require ListDistroSequence
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $( ListDistroSequence $useNoCache $useNoIndex --all ) ; do
					ListProjectProvides "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--add-own-provides-column)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project provides filter is expected!" >&2
					return 1
				fi
				local columnMatcher="$1" ; shift
				if [ -z "$indexOwnProvides" ] ; then
					local indexOwnProvides="` ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides `"
				fi
				
				local indexCurrent="` \
					if [ -z "$indexColumns" ] ; then
						if [ -z "$projectsSelected" ] ; then
							echo "$indexOwnProvides" | cut -d" " -f1 | sort
						else
							echo "$projectsSelected" | sort
						fi
					else
						echo "$indexColumns" | sort
					fi
				`"

				case "$columnMatcher" in
					*:)
						local indexFiltered="` echo "$indexOwnProvides" | grep -e "^.* $columnMatcher.*$" | sed -e "s| $columnMatcher| |" | awk '$0 && !x[$0]++' | sort `"
					;;
					*)
						local indexFiltered="` echo "$indexOwnProvides" | grep -e "^.* $columnMatcher$" | awk '$0 && !x[$0]++' | sort `"
					;;
				esac
				
				local indexColumns="` join -11 -21 <( echo "$indexCurrent" ) <( echo "$indexFiltered" ) `"
				if [ -z "$indexColumns" ] ; then
					echo "ERROR: ListDistroProvides: --add-provides-column no projects selected!" >&2
					return 1
				fi
			;;
			--add-merged-provides-column)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project provides filter is expected!" >&2
					return 1
				fi
				local columnMatcher="$1" ; shift
				if [ -z "$indexAllProvides" ] ; then
					local indexAllProvides="` ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides-merged `"
				fi

				local indexCurrent="` \
					if [ -z "$indexColumns" ] ; then
						if [ -z "$projectsSelected" ] ; then
							echo "$indexAllProvides" | cut -d" " -f1 | awk '!x[$0]++' | sort
						else
							echo "$projectsSelected" | sort
						fi
					else
						echo "$indexColumns" | sort
					fi
				`"

				case "$columnMatcher" in
					*:)
						local indexFiltered="` echo "$indexAllProvides" | cut -d" " -f1,3 | grep -e "^.* $columnMatcher.*$" | sed -e "s| $columnMatcher| |" | awk '$0 && !x[$0]++' | sort `"
					;;
					*)
						local indexFiltered="` echo "$indexAllProvides" | cut -d" " -f1,3 | grep -e "^.* $columnMatcher$" | awk '$0 && !x[$0]++' | sort `"
					;;
				esac

				local indexColumns="` join <( echo "$indexCurrent" ) <( echo "$indexFiltered" ) `"
				if [ -z "$indexColumns" ] ; then
					echo "ERROR: ListDistroProvides: --add-merged-provides-column no projects selected!" >&2
					return 1
				fi
			;;
			--merge-sequence)
				shift
				if [ -z "$projectsSelected" ] ; then
					echo "ERROR: ListDistroProvides: --merge-sequence, no projects selected!" >&2
					return 1
				fi
				
				Require ListProjectProvides
		
				local sequenceProjectName
				for sequenceProjectName in $projectsSelected ; do
					ListProjectProvides "$sequenceProjectName" --merge-sequence $useNoCache $useNoIndex "$@" | sed "s|^|$sequenceProjectName |g"
				done | awk '!x[$0]++'
				return 0
			;;
			--filter-and-cut)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProvides: project provides filter is expected!" >&2
					return 1
				fi
				local filterProvides="$1" ; shift

				ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides | while read -r LINE ; do
					ListDistroProvides --internal-print-project-provides-filter $filterProvides $LINE
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
				
				if [ ! -z "$projectsSelected" ] ; then
					awk 'NR==FNR{a[$1]=$0;next} ($1 in a){b=$1;$1="";print a[b]  $0}' <( \
						echo "$projectsSelected" \
					) <( \
						ListDistroProvides --explicit-noop $useNoCache $useNoIndex --all-provides \
					)
					return 0
				fi

				echo "ERROR: ListDistroProvides: no projects selected!" >&2
				return 1
			;;
			*)
				echo "ListDistroProvides: invalid option: $1" >&2
				return 1
			;;
		esac
	done

}

case "$0" in
	*/sh-scripts/ListDistroProvides.fn.sh)
		# ListDistroProvides.fn.sh --distro-source-only deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-source deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached deploy-keyword 2> /dev/null | grep " bhyve$"
		# ListDistroProvides.fn.sh --distro-from-cached deploy-ssh-target 2> /dev/null

		# ListDistroProvides.fn.sh --distro-from-cached --select-projects tbd9 deploy-ssh-target 2> /dev/null
		# ListDistroProvides.fn.sh --distro-from-cached --select-projects tbd9 deploy-keyword 2> /dev/null

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProvides.fn.sh [--print-provides-only] <search> [--merge-sequence]" >&2
			echo "syntax: ListDistroProvides.fn.sh [--print-provides-only] --all-provides [--merge-sequence]" >&2
			echo "syntax: ListDistroProvides.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --select-{all|sequence|changed|none} " >&2
				echo "    --{select|filter|remove}-{projects|[merged-]provides|[merged-]keywords} <glob>" >&2
				echo "  examples:" >&2
				echo "    ListDistroProvides.fn.sh --distro-from-source --all-provides 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-from-cached --all-provides | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-source-only --all-provides | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-projects macosx 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-projects macosx --merge-sequence 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-projects myx | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-projects myx --filter-projects l6b2 --no-cache --no-index | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-keywords myx | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-keywords l6 | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-provides deploy-ssh-target: 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-merged-provides deploy-l6route-config: 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --distro-source-only --select-merged-provides deploy-l6route-config 2> /dev/null | sort" >&2
				echo "    ListDistroProvides.fn.sh --select-projects l6b2 --merge-sequence 2> /dev/null" >&2
				echo "    ListDistroProvides.fn.sh --print-provides-only --select-merged-provides source-process: 2> /dev/null" >&2
				echo "    ListDistroProvides.fn.sh --print-provides-only --select-merged-provides source-process: --merge-sequence 2> /dev/null" >&2
				echo "    ListDistroProvides.fn.sh --select-merged-keywords l6 --filter-projects myx --merge-sequence 2> /dev/null" >&2
			fi
			exit 1
		fi
		
		ListDistroProvides "$@"
	;;
esac