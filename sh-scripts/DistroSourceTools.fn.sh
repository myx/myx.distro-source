#!/usr/bin/env bash

##
## NOTE:
## Designed to be able to run without distro context. Used to install required parts.
##

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/.local" ] || ( echo "⛔ ERROR: expecting '.local' directory." >&2 && exit 1 )
fi

DistroSourceTools(){
	local MDSC_CMD='DistroSourceTools'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD" $MDSC_NO_CACHE $MDSC_NO_INDEX "$@" >&2

	set -e

	while true ; do
		. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
		case "$1" in
			--*-config-option)
				. "$MDLT_ORIGIN/myx/myx.distro-.local/sh-lib/LocalTools.Config.include"
				return 0
			;;
			## List all repository roots by listing root configuration files directory
			--list-repository-roots|--list-namespace-roots)
				shift
				local REPO_ROOTS="$MMDAPP/.local/roots"
				[ -d "$REPO_ROOTS" ] || return 0
				local REPO_ROOT_LIST=$(ls -d "$REPO_ROOTS"/*.distro-namespace 2>/dev/null || :)
				[ -n "$REPO_ROOT_LIST" ] || return 0
				local repositoryName
				for repositoryName in $REPO_ROOT_LIST; do
					repositoryName="${repositoryName#$MMDAPP/.local/roots/}"
					repositoryName="${repositoryName%.distro-namespace}"
					echo "$repositoryName"
				done
				return 0
			;;
			--register-repository-roots|--register-namespace-roots)
				shift
				while [ $# -gt 0 ] ; do
					DistroSourceTools --register-namespace-root "$1" --not-set --batch
					shift
				done
				DistroSourceTools --make-code-workspace --quiet
				return 0
			;;
			--unregister-repository-roots|--unregister-namespace-roots)
				shift
				while [ $# -gt 0 ] ; do
					DistroSourceTools --unregister-namespace-root "$1" --batch
					shift
				done
				DistroSourceTools --make-code-workspace --quiet
				return 0
			;;
			--register-repository-root|--register-namespace-root)
				local repositoryName="$2"
				local repositoryHref="$3"
				if [ -z "$repositoryName" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: repository root name expected: $@" >&2
					set +e ; return 1
				fi
				if [ -z "$repositoryHref" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: repository root href expected: $@" >&2
					set +e ; return 1
				fi

				shift 3

				if [ "$1" == "--batch" ] ; then
					shift
					local partOfBatch="false"
				fi
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --register-namespace-root <namespace-root-name> <repo-href> option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				local repositoryInf="$(
					printf \
						"# created by DistroSourceTools --register-namespace-root '%s'\nName: %s\nHref: %s\nFetch: %s\n" \
						"$repositoryName" \
						"$repositoryName" \
						"$repositoryHref" \
						"$repositoryHref"
				)"

				mkdir -p "$MMDAPP/.local/roots" "$MMDAPP/source/$repositoryName"

				local changed=""

				local repositoryRoot="$MMDAPP/.local/roots/$repositoryName.distro-namespace"

				if [ ! -f "$repositoryRoot" ] || [ "$( cat "$repositoryRoot" 2>/dev/null )" = "$repositoryInf" ] ; then
					echo -n "$repositoryInf" > "$repositoryRoot"
					echo "> $MDSC_CMD: --register-namespace-root: ${repositoryRoot#$MMDAPP/} (re-)created." >&2
					changed=true
				fi


				local repositoryFile="$MMDAPP/source/$repositoryName/repository.inf"

				if [ ! -f "$repositoryFile" ] || [ "$( cat "$repositoryFile" 2>/dev/null )" = "$repositoryInf" ] ; then
					echo -n "$repositoryInf" > "$repositoryFile"
					echo "> $MDSC_CMD: --register-namespace-root: ${repositoryFile#$MMDAPP/} (re-)created." >&2
					changed=true
				fi

				[ -z "$changed" ] || [ -n "$partOfBatch" ] || DistroSourceTools --make-code-workspace --quiet

				return 0
			;;
			--unregister-repository-root|--unregister-namespace-root)
				local repositoryName="$2"
				if [ -z "$repositoryName" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: repository root name expected: $@" >&2
					set +e ; return 1
				fi

				shift 2

				if [ "$1" == "--batch" ] ; then
					shift
					local partOfBatch="false"
				fi

				local changed=""

				local repositoryRoot="$MMDAPP/.local/roots/$repositoryName.distro-namespace"
				local repositoryFile="$MMDAPP/source/$repositoryName/repository.inf"

				[ -f "$repositoryRoot" || -f "$repositoryFile" ] || {
					echo "🙋 WARNING: $MDSC_CMD: repository root $repositoryName is unknown." >&2
					continue
					# echo "⛔ ERROR: $MDSC_CMD: repository root $repositoryName is unknown." >&2
					# set +e ; return 1
				}

				if [ -f "$repositoryRoot" ]; then
					rm "$repositoryRoot"
					echo "> $MDSC_CMD: --unregister-namespace-root: ${repositoryRoot#$MMDAPP/} deleted." >&2
					changed=true
				fi

				if [ -f "$repositoryFile" ] ; then
					rm "$repositoryFile"
					echo "> $MDSC_CMD: --unregister-namespace-root: ${repositoryFile#$MMDAPP/} deleted." >&2
				fi

				[ -n "$partOfBatch" ] || DistroSourceTools --make-code-workspace --quiet

				continue
			;;
			--make-*)
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/SourceTools.Make.include"
				return 0
			;;
			--upgrade-source-tools)
				shift
				bash "$MDLT_ORIGIN/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh" --install-distro-source
				return 0
			;;
			--help|--help-syntax)
				echo "📘 syntax: DistroSourceTools.fn.sh <option>" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh --register-namespace-root <namespace-root-name>" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh --upgrade-source-tools" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh [--help]" >&2
				if [ "$1"="--help" ] ; then
					cat "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.DistroSourceTools.text" >&2
				fi
				return 0
			;;
			*)
				echo "⛔ ERROR: $MDSC_CMD: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done
}

case "$0" in
	*/myx/myx.distro-source/sh-scripts/DistroSourceTools.fn.sh)

		set -e
		if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
			. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-source/sh-lib/SourceContext.include"
		fi
		DistroSystemContext --distro-path-auto

		if [ -z "$1" ] || [ "$1"="--help" ] ; then
			if [ -z "$1" ] || [ ! -f "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/Help.DistroSourceTools.text" ] ; then
				echo "📘 syntax: DistroSourceTools.fn.sh --register-namespace-root <namespace-root-name>" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh --upgrade-source-tools" >&2
			else
				DistroSourceTools "${1:-"--help-syntax"}"
			fi
			exit 1
		fi

		DistroSourceTools "$@"
	;;
esac
