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
	if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
		. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-source/sh-lib/SourceContext.include"
	fi
	DistroSystemContext --distro-path-auto

	local MDSC_CMD='DistroSourceTools'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD" $MDSC_NO_CACHE $MDSC_NO_INDEX "$@" >&2

	set -e

	while true ; do
		case "$1" in
			--register-repository-roots)
				shift
				while [ $# -gt 0 ] ; do
					DistroSourceTools --register-repository-root "$1" --not-set --batch
					shift
				done
				return 0
			;;
			--register-repository-root)
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

				shift ; shift ; shift

				if [ "$1" == "--batch" ] ; then
					shift
					local partOfBatch="false"
				fi
				if [ -n "$1" ] ; then
					echo "⛔ ERROR: $MDSC_CMD: no options allowed after --register-repository-root <repo-name> <repo-href> option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi

				mkdir -p "$MMDAPP/source/$repositoryName"

				local repositoryInf="$(
					printf \
						"# created by DistroSourceTools --register-repository-root '%s'\nName: %s\nHref: %s\nFetch: %s\n" \
						"$repositoryName" \
						"$repositoryName" \
						"$repositoryHref" \
						"$repositoryHref"
				)"

				local repositoryFile="$MMDAPP/source/$repositoryName/repository.inf"

				if ! [ "$( cat "$repositoryFile" 2>/dev/null )" == "$repositoryInf" ] ; then
					echo -n "$repositoryInf" > "$repositoryFile"
					echo "> $MDSC_CMD: --register-repository-root: $repositoryFile (re-)created." >&2
					DistroSourceTools --make-code-workspace --quiet
				fi

				return 0
			;;
			--make-*)
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/SourceTools.Make.include"
				return 0
			;;
			--*-config-option)
				. "$MDLT_ORIGIN/myx/myx.distro-.local/sh-lib/LocalTools.Config.include"
				return 0
			;;
			--upgrade-source-tools)
				shift
				bash "$MDLT_ORIGIN/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh" --install-distro-source
				return 0
			;;
			--help|--help-syntax)
				echo "📘 syntax: DistroSourceTools.fn.sh <option>" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh --register-repository-root <repo-name>" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh --upgrade-source-tools" >&2
				echo "📘 syntax: DistroSourceTools.fn.sh [--help]" >&2
				if [ "$1" = "--help" ] ; then
					cat "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpDistroSourceTools.text" >&2
				fi
				return 0
			;;
			--verbose)
				shift
				export MDSC_DETAIL="true"
				continue
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

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			DistroSourceTools "${1:-"--help-syntax"}"
			exit 1
		fi

		DistroSourceTools "$@"
	;;
esac
