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
				local selectProjects="$MDSC_SELECT_PROJECTS"
				if [ -z "$selectProjects" ] ; then
					echo "ERROR: ListDistroProjects: --select-from-env no projects selected!" >&2
					return 1
				fi
			;;
			--all-projects)
				shift
				if [ ! -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --all-projects option ($MDSC_OPTION, $@)" >&2
					return 1
				fi
				
				if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
					if [ "$useNoCache" != "--no-cache" ] ; then
						local cacheFile="$MDSC_CACHED/all-project-names.txt"
						if [ ! -z "$MDSC_CACHED" ] && [ -f "$cacheFile" ] && \
							( [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$cacheFile" "+%Y%m%d%H%M%S"`" ] ) ; then
							[ -z "$MDSC_DETAIL" ] || echo "| ListDistroProjects: using cached ($MDSC_OPTION)" >&2
							cat "$cacheFile"
							return 0
						fi
						if [ ! -z "$MDSC_CACHED" ] && [ -d "$MDSC_CACHED" ] ; then
							echo "| ListDistroProjects: caching projects ($MDSC_OPTION)" >&2
							ListDistroProjects --no-cache --all-projects > "$cacheFile"
							cat "$cacheFile"
							return 0
						fi
					fi
					if [ "$useNoIndex" != "--no-index" ] ; then
						local indexFile="$MDSC_CACHED/distro-index.inf"
						if [ -f "$indexFile" ] && \
							( [ "$MDSC_INMODE" = "distro" ] || [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$indexFile" "+%Y%m%d%H%M%S"`" ] )
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
				local selectProjects="`ListDistroProjects $useNoCache $useNoIndex --all-projects`"
			;;
			--select-sequence)
				##
				## Replaces selection with 'all projects sequence'
				##
				shift
				
				Require ListDistroSequence
				local selectProjects="`ListDistroSequence $useNoCache $useNoIndex --all`"
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
				local selectProjects="` cat <( echo "$selectProjects" ) <( ListChangedSourceProjects $useNoCache $useNoIndex --all ) | awk '$0 && !x[$0]++' `"
			;;

			--select-projects|--select-provides|--select-merged-provides|--select-keywords|--select-merged-keywords|--select-repository-projects)
				## Unions with selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					return 1
				fi
				local selectArgument="$1" ; shift
				if [ -z "${MDSC_IDAPRV:0:1}" ] ; then
					Require ListDistroProvides
					ListDistroProvides --set-env MDSC_IDAPRV --all-provides-merged
				fi
				local selectProjects="` \
					cat \
						<( echo "$selectProjects" ) \
						<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--select}" "$selectArgument" ) \
					| awk '$0 && !x[$0]++' \
				`"
			;;
			--filter-projects|--filter-provides|--filter-merged-provides|--filter-keywords|--filter-merged-keywords|--filter-repository-projects)
				## Intersects with selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					return 1
				fi
				local selectArgument="$1" ; shift
				if [ -z "${MDSC_IDAPRV:0:1}" ] ; then
					Require ListDistroProvides
					ListDistroProvides --set-env MDSC_IDAPRV --all-provides-merged
				fi
				local selectProjects="` \
					grep -Fx -f \
						<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--filter}" "$selectArgument" ) \
						<( echo "$selectProjects" ) \
					| awk '$0 && !x[$0]++' \
				`"
			;;
			--remove-projects|--remove-provides|--remove-merged-provides|--remove-keywords|--remove-merged-keywords|--remove-repository-projects)
				## Subtracts from selection
				local selectVariant="$1" ; shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: $selectVariant selectArgument is expected!" >&2
					return 1
				fi
				local selectArgument="$1" ; shift
				if [ -z "${MDSC_IDAPRV:0:1}" ] ; then
					Require ListDistroProvides
					ListDistroProvides --set-env MDSC_IDAPRV --all-provides-merged
				fi
				local selectProjects="` \
					grep -Fvx -f \
						<( ListDistroProjects $useNoCache $useNoIndex "-${selectVariant#--remove}" "$selectArgument" ) \
						<( echo "$selectProjects" ) \
					| awk '$0 && !x[$0]++' \
				`"
			;;

			--projects)
				##
				## Prints projects whose name matches the glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --projects projectName filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --projects option ($MDSC_OPTION)" >&2
					return 1
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
					echo "ERROR: ListDistroProjects: --projects projectName filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --projects option ($MDSC_OPTION)" >&2
					return 1
				fi
				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				case "$providesFilter" in
					*:)
						ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* $providesFilter.*$" | awk '{print $1}' | awk '$1 && !x[$1]++'
						return 0
					;;
					*)
						ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* $providesFilter$" | awk '{print $1}' | awk '$1 && !x[$1]++'
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
					echo "ERROR: ListDistroProjects: --projects projectName filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --projects option ($MDSC_OPTION)" >&2
					return 1
				fi
				local providesFilter="$1" ; shift

				Require ListDistroProvides

				case "$providesFilter" in
					*:)
						ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* $providesFilter.*$" | awk '{print $1}' | awk '$1 && !x[$1]++'
						return 0
					;;
					*)
						ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* $providesFilter$" | awk '{print $1}' | awk '$1 && !x[$1]++'
						return 0
					;;
				esac
			;;
			--keywords)
				##
				## Prints projects whose provides match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --keywords keyword filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --keywords option ($MDSC_OPTION)" >&2
					return 1
				fi

				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				ListDistroProvides $useNoCache $useNoIndex --all-provides | grep -e "^.* deploy-keyword:$providesFilter$" | awk '{print $1}' | awk '$1 && !x[$1]++'
				return 0
			;;
			--merged-keywords)
				##
				## Prints projects whose provides match glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --merged-keywords keyword filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --keywords option ($MDSC_OPTION)" >&2
					return 1
				fi

				local providesFilter="$1" ; shift

				Require ListDistroProvides
				
				ListDistroProvides $useNoCache $useNoIndex --all-provides-merged | grep -e "^.* deploy-keyword:$providesFilter$" | awk '{print $1}' | awk '$1 && !x[$1]++'
				return 0
			;;
			--repository-projects)
				##
				## Prints projects whose name matches the glob
				##
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --repository-projects projectName filter is expected!" >&2
					return 1
				fi
				if [ ! -z "$2" ] ; then
					echo "ERROR: ListDistroProjects: no options allowed after --repository-projects option" >&2
					return 1
				fi
				local projectFilter="$1" ; shift

				ListDistroProjects $useNoCache $useNoIndex --all-projects | grep -e "^$projectFilter/.*$"
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
					return 1
				fi
				local executeDefault="$1" ; shift
			;;
			--select-execute-command)
				shift
				if [ -z "$1" ] ; then
					echo "ERROR: ListDistroProjects: --select-execute-command command is expected!" >&2
					return 1
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
					return 1
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
		
		#	ListDistroProjects.fn.sh
		#	( . "`which ListDistroProjects.fn.sh`" ; ListDistroProjects )
		
		#   ListDistroProjects.fn.sh --distro-source-only 2> /dev/null | sort
		#	ListDistroProjects.fn.sh --distro-from-source 2> /dev/null | sort
		
		#	ListDistroProjects.fn.sh --distro-from-output
		#	ListDistroProjects.fn.sh --distro-from-cached
		#	ListDistroProjects.fn.sh --distro-from-distro
		
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListDistroProjects.fn.sh --all-projects" >&2
			echo "syntax: ListDistroProjects.fn.sh <search>" >&2
			echo "syntax: ListDistroProjects.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --select-{all|sequence|changed|none} " >&2
				echo "    --{select|filter|remove}-{projects|[merged-]provides|[merged-]keywords} <glob>" >&2
				echo "    --{select|filter|remove}-repository-projects <repositoryName>" >&2
				echo "  Examples:" >&2
				
				echo "    ListDistroProjects.fn.sh --distro-from-source --select-all 2> /dev/null | sort" >&2
				echo "    ListDistroProjects.fn.sh --distro-from-cached --select-all | sort" >&2
				echo "    ListDistroProjects.fn.sh --distro-source-only --select-all | sort" >&2

				echo "    ListDistroProjects.fn.sh --all-projects | sort" >&2
				echo "    ListDistroProjects.fn.sh --select-sequence | sort" >&2
				echo "    ListDistroProjects.fn.sh --select-all | sort" >&2
				echo "    ListDistroProjects.fn.sh --select-changed | sort" >&2

				echo "    ListDistroProjects.fn.sh --select-projects my --select-projects common --select-projects ndss --remove-projects prv --filter-projects tbd | sort" >&2
				echo "    ListDistroProjects.fn.sh --select-merged-keywords l6 --filter-provides deploy-ssh-target: 2> /dev/null | sort" >&2
				echo "    ListDistroProjects.fn.sh --select-merged-provides deploy-keyword:l6 --filter-provides deploy-ssh-target: 2> /dev/null | sort" >&2

				echo "    ListDistroProjects.fn.sh --projects ndss | sort" >&2
				echo "    ListDistroProjects.fn.sh --provides image-execute:deploy-l6route-config: | sort" >&2
				echo "    ListDistroProjects.fn.sh --provides deploy-keyword:l6 | sort" >&2
				echo "    ListDistroProjects.fn.sh --keywords deploy-keyword:l6 | sort" >&2
			fi
			exit 1
		fi
		
		ListDistroProjects "$@"
	;;
esac