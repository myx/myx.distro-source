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


ListDistroProjects(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListDistroProjects $@" >&2

	set -e

	local selectProjects=""

	local executeDefault=""
	
	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
			--select-from-env)
				shift
				local selectProjects="${MDSC_SELECT_PROJECTS}"
				if [ -z "$selectProjects" ] ; then
					echo "ERROR: ListDistroProjects: --select-from-env no projects selected!" >&2
					set +e ; return 1
				fi
			;;
			--all-projects)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --all-projects option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoCache" != "--no-cache" ] ; then
						local cacheFile="$MDSC_CACHED/all-project-names.txt"
						if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
							( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "$( date -u -r "$cacheFile" "+%Y%m%d%H%M%S" )" ] ) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| ListDistroProjects: using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
						if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
							echo "| ListDistroProjects: caching projects ($MDSC_OPTION)" >&2
							ListDistroProjects --no-cache --all-projects | tee "$cacheFile"
							return 0
						fi
					fi
					if [ "$useNoIndex" != "--no-index" ] ; then
						local indexFile="$MDSC_CACHED/distro-index.inf"
						if [ -f "$indexFile" ] && \
							( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "$( date -u -r "$indexFile" "+%Y%m%d%H%M%S" )" ] )
						then
							echo "| ListDistroProjects: using image ($MDSC_OPTION)" >&2
							local projectName
							for projectName in $( grep -e "^PRJS=" "$indexFile" | sed "s:^.*=::" | tr ' ' '\n' ) ; do
								echo "$projectName"
							done
							return 0
						fi
					fi
				fi
				
				echo "| ListDistroProjects: scanning all projects ($MDSC_OPTION)" >&2
			
				Require ListAllRepositories
				Require ListRepositoryProjects
				
				local repositoryName
				ListAllRepositories | while read repositoryName ; do
					ListRepositoryProjects "$repositoryName"
				done
				
				return 0
			;;
			--print-selected)
				shift
				echo "$selectProjects"
			;;
			--select-all)
				##
				## Replaces selection with 'all projects'
				##
				shift
				local selectProjects
				selectProjects="$( ListDistroProjects $useNoCache $useNoIndex --all-projects )"
			;;
			--select-sequence)
				##
				## Replaces selection with 'all projects sequence'
				##
				shift
				
				Require ListDistroSequence
				local selectProjects
				selectProjects="$( ListDistroSequence $useNoCache $useNoIndex --all )"
			;;
			--select-none)
				##
				## Replaces selection with 'no projects selected'
				##
				shift
				local selectProjects=""
			;;
			--select-changed)
				##
				## Unions selection with 'changed projects'
				##
				shift

				Require ListChangedSourceProjects
				local selectProjects
				selectProjects="$( cat <( echo "$selectProjects" ) <( ListChangedSourceProjects $useNoCache $useNoIndex --all ) | awk '$0 && !x[$0]++' )"
			;;

			#--select-{projects|provides|merged-provides|declares|keywords|merged-keywords|keywords2|merged-keywords2|one-project})
			--select-projects|--select-provides|--select-merged-provides|--select-declares|--select-keywords|--select-merged-keywords|--select-keywords2|--select-merged-keywords2|--select-one-project)
				## Unions with selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					set +e ; return 1
				fi
				local selectArgument="$1" ; shift

				local matchingProjects # local hides exit-code handling #
				matchingProjects="$( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--select}" "$selectArgument" )"

				if [ -z "$matchingProjects" ] ; then
					echo "ListDistroProjects: 🙋 WARNING: No matching projects found (search: $selectVariant $selectArgument)." >&2
				else
					local selectProjects
					selectProjects="$( \
						printf "%s\n%s" "$selectProjects" "$matchingProjects" \
						| awk '$0 && !x[$0]++' \
					)"
				fi

				#selectProjects="` \
				#	{ \
				#		echo "$selectProjects" ; \
				#		ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--select}" "$selectArgument" ; \
				#	} | awk '$0 && !x[$0]++' \
				#`"

				#selectProjects="` \
				#	cat \
				#		<( echo "$selectProjects" ) \
				#		<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--select}" "$selectArgument" || echo 1 ) \
				#	| awk '$0 && !x[$0]++' \
				#`"
			;;
			--filter-projects|--filter-provides|--filter-merged-provides|--filter-declares|--filter-keywords|--filter-merged-keywords|--filter-keywords2|--filter-merged-keywords2|--filter-one-project)
				## Intersects with selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					set +e ; return 1
				fi
				local selectArgument="$1" ; shift
				local matchingProjects # local hides exit-code handling #
				matchingProjects="$( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--filter}" "$selectArgument" )"
				if [ -z "$matchingProjects" ] ; then
					echo "ListDistroProjects: 🙋 WARNING: No matching projects found (search: $selectVariant $selectArgument)." >&2
					local selectProjects=""
				else
					local selectProjects
					selectProjects="` \
						grep -Fx -f \
							<( echo "$matchingProjects" ) \
							<( echo "$selectProjects" ) \
						| awk '$0 && !x[$0]++' \
					`"
				fi
				#selectProjects="` \
				#	grep -Fx -f \
				#		<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--filter}" "$selectArgument" ) \
				#		<( echo "$selectProjects" ) \
				#	| awk '$0 && !x[$0]++' \
				#`"
			;;
			--remove-projects|--remove-provides|--remove-merged-provides|--remove-provides|--remove-keywords|--remove-merged-keywords|--remove-keywords2|--remove-merged-keywords2|--remove-one-project)
				## Subtracts from selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					set +e ; return 1
				fi
				local selectArgument="$1" ; shift
				local matchingProjects # local hides exit-code handling #
				matchingProjects="$( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--remove}" "$selectArgument" )"
				if [ -z "$matchingProjects" ] ; then
					echo "ListDistroProjects: 🙋 WARNING: No matching projects found (search: $selectVariant $selectArgument)." >&2
				else
					local selectProjects
					selectProjects="` \
						grep -Fvx -f \
							<( echo "$matchingProjects" ) \
							<( echo "$selectProjects" ) \
						| awk '$0 && !x[$0]++' \
					`"
				fi
				#selectProjects="` \
				#	grep -Fvx -f \
				#		<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--remove}" "$selectArgument" ) \
				#		<( echo "$selectProjects" ) \
				#	| awk '$0 && !x[$0]++' \
				#`"
			;;

			--one-project)
				##
				## Prints exactly one project (or fails) whose name matches the glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --one-project projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --one-project option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi

				if [ -f "$MDSC_SOURCE/$1/project.inf" ] ; then # exact match, beats all
					echo "$1"
					return 0
				fi

				local projectFilter="$1" ; shift

				local matchedProjects
				matchedProjects="$( ListDistroProjects $useNoCache $useNoIndex --all-projects | ( grep -e "^.*$projectFilter.*$" || true ) )"

				if [ -z "$matchedProjects" ] ; then
					echo "ListDistroProjects: ⛔ ERROR: No matching projects found (exactly one requested, --one-project $projectFilter)." >&2
					set +e ; return 1
				fi
				
				if [ "$matchedProjects" != "$( echo "$matchedProjects" | head -n 1 )" ] ; then
					echo "ListDistroProjects: 🙋 STOP: More than one match (exactly one requested, --one-project $projectFilter): $@" >&2
					echo "$matchedProjects" | sed -e "s|^|        >> |g" >&2
					set +e ; return 2
				fi

				echo "$matchedProjects"				
				return 0
			;;
			--projects)
				##
				## Prints projects whose name matches the glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --projects projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --projects option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local projectFilter="$1" ; shift

				ListDistroProjects $useNoCache $useNoIndex --all-projects | grep -e "^.*$projectFilter.*$"
				return 0
			;;
			--provides)
				##
				## Prints projects whose provides match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --provides projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --provides option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				case "$providesFilter" in
					*:)
						ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* $providesFilter.*$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
					*)
						ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* $providesFilter$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
				esac
			;;
			--merged-provides)
				##
				## Prints projects whose provides match glob
				##
				##
				## Prints projects whose name matches the glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --merged-provides projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --merged-provides option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local providesFilter="$1" ; shift

				Require ListDistroProvides

				case "$providesFilter" in
					*:)
						ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* $providesFilter.*$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
					*)
						ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* $providesFilter$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
				esac
			;;
			--declares)
				##
				## Prints projects whose declares match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --declares projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --declares option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local declaresFilter="$1" ; shift

				Require ListDistroDeclares
				
				case "$declaresFilter" in
					*:)
						ListDistroDeclares $useNoCache $useNoIndex --all-declares | grep -e "^.* $declaresFilter.*$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
					*)
						ListDistroDeclares $useNoCache $useNoIndex --all-declares | grep -e "^.* $declaresFilter$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
				esac
			;;
			--keywords2) # old, to be deleted later
				##
				## Prints projects whose provides match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --keywords keyword filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --keywords option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi

				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* deploy-keyword:$providesFilter$" | awk '$1 && !x[$1]++ { print $1; }'
				return 0
			;;
			--keywords)
				##
				## Prints projects whose keywords match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --keywords projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --keywords option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local keywordsFilter="$1" ; shift

				Require ListDistroKeywords
				
				case "$keywordsFilter" in
					*:)
						ListDistroKeywords $useNoCache $useNoIndex --all-keywords | grep -e "^.* $keywordsFilter.*$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
					*)
						ListDistroKeywords $useNoCache $useNoIndex --all-keywords | grep -e "^.* $keywordsFilter$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
				esac
			;;
			--merged-keywords2) # old, to be deleted later
				##
				## Prints projects whose provides match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --merged-keywords keyword filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --merged-keywords option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi

				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* deploy-keyword:$providesFilter$" | awk '$1 && !x[$1]++ { print $1; }'
				return 0
			;;
			--merged-keywords)
				##
				## Prints projects whose keywords match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --keywords projectName filter is expected!" >&2
					set +e ; return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --keywords option ($MDSC_OPTION)" >&2
					set +e ; return 1
				fi
				local keywordsFilter="$1" ; shift

				Require ListDistroKeywords
				
				case "$keywordsFilter" in
					*:)
						ListDistroKeywords $useNoCache $useNoIndex --all-keywords-merged | grep -e "^.* $keywordsFilter.*$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
					*)
						ListDistroKeywords $useNoCache $useNoIndex --all-keywords-merged | grep -e "^.* $keywordsFilter$" | awk '$1 && !x[$1]++ { print $1; }'
						return 0
					;;
				esac
			;;

			--select-required|--select-affected|--select-required-projects|--select-affected-projects)
				## Adds projects required or affected by current selection
				[ "$MDSC_DETAIL" == "full" ] || echo "* ListDistroProjects: $1, selected: $( echo $selectProjects )" >&2

				local selectVariant="--${1#--select-}" ; shift

				selectProjects="$( 
					export MDSC_SELECT_PROJECTS="$selectProjects"
					ListDistroProjects $useNoCache $useNoIndex --select-from-env $selectVariant 
				)"
			;;
			--required|--required-projects)

				Require ListDistroSequence
				ListDistroSequence --all-projects \
				| awk -v list="$( echo $selectProjects )" '
					BEGIN {
						n = split(list, arr, " ")
						for (i = 1; i <= n; i++) keys[arr[i]] = 1
					}
					($1 in keys) && !seen[$2]++ { print $2 }
				'

				return 0
			;;
			--affected|--affected-projects)

				Require ListDistroSequence
				ListDistroSequence --all-projects \
				| awk -v list="$( echo $selectProjects )" '
					BEGIN {
						n = split(list, arr, " ")
						for (i = 1; i <= n; i++) keys[arr[i]] = 1
					}
					($2 in keys) && !seen[$1]++ { print $1 }
				'

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
			--select-execute-default)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --select-execute-default command is expected!" >&2
					set +e ; return 1
				fi
				local executeDefault="$1" ; shift
			;;
			--select-execute-command)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --select-execute-command command is expected!" >&2
					set +e ; return 1
				fi
				local executeCommand="$1" ; shift

				export MDSC_SELECT_PROJECTS="$selectProjects"
				$executeCommand --select-from-env $useNoCache $useNoIndex "$@"
				return 0
			;;
			*)
				if [ -z "$executeDefault" ] ; then
					if [ -z "$1" ] ; then
						echo "$selectProjects"
						return 0
					fi

					echo "ERROR: ListDistroProjects: invalid option ($1), expecting <command name> <args...>: $1" >&2
					set +e ; return 1
				fi
				export MDSC_SELECT_PROJECTS="$selectProjects"
				[ -z "$MDSC_DETAIL" ] || echo "* ListDistroProjects:" $executeDefault --select-from-env $useNoCache $useNoIndex "$@" >&2
				$executeDefault --select-from-env $useNoCache $useNoIndex "$@"
				return 0
			;;
		esac
	done
}

case "$0" in
	*/sh-scripts/ListDistroProjects.fn.sh) 
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProjects.fn.sh --all-projects" >&2
			echo "syntax: ListDistroProjects.fn.sh <project-selector> [<options>] [<execute-extra-args>]" >&2
			echo "syntax: ListDistroProjects.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpListDistroProjects.include"
			fi
			exit 1
		fi
		
		ListDistroProjects "$@"
	;;
esac
