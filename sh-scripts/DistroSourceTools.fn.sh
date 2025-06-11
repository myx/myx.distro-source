#!/usr/bin/env bash

##
## NOTE:
## Designed to be able to run without distro context. Used to install required parts.
##

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/.local" ] || ( echo "ERROR: expecting '.local' directory." >&2 && exit 1 )
fi

DistroSourceTools(){
	local MDSC_CMD='DistroSourceTools'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	case "$1" in
		--register-repository-root)
			local repositoryName="$2"
			local repositoryHref="$3"
			if [ -z "$repositoryName" ] ; then
				echo "ERROR: $MDSC_CMD: repository root name expected: $@" >&2
				set +e ; return 1
			fi
			if [ -z "$repositoryHref" ] ; then
				echo "ERROR: $MDSC_CMD: repository root href expected: $@" >&2
				set +e ; return 1
			fi

			shift ; shift ; shift

			if [ ! -z "$1" ] ; then
				echo "ERROR: $MDSC_CMD: no options allowed after --register-repository-root <repo-name> <repo-href> option ($MDSC_OPTION, $@)" >&2
				set +e ; return 1
			fi

			mkdir -p "$MMDAPP/source/$repositoryName"

			local repositoryInf="$(
				printf \
					"# created by DistroSourceToops --register-repository-root '%s'\nName: %s\Href: %s\nFetch: %s\n" \
					"$repositoryName" \
					"$repositoryName" \
					"$repositoryHref" \
					"$repositoryHref"
			)"

			if ! [ "$( cat "$MMDAPP/source/$repositoryName/repository.inf" )" == "$repositoryInf" ] ; then
				echo -n "$repositoryInf" > "$MMDAPP/source/$repositoryName/repository.inf"
				echo "> $MDSC_CMD: --register-repository-root: $MMDAPP/source/$repositoryName/repository.inf (re-)created." >&2
				DistroSourceTools --make-code-workspace --quiet
			fi

			return 0
		;;
		--make-*)
			. "$MMDAPP/.local/myx/myx.distro-source/sh-lib/DistroSourceToolsMake.include"
			set +e ; return 1
		;;
		--system-config-option|--custom-config-option)
			. "$MMDAPP/.local/myx/myx.distro-source/sh-lib/DistroSourceToolsConfig.include"
			set +e ; return 1
		;;
		--completion-*)
			. "$MMDAPP/.local/myx/myx.distro-source/sh-lib/DistroSourceToolsCompletion.include"
			set +e ; return 1
		;;
		--upgrade-source-tools)
			shift
			bash "$MMDAPP/.local/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh" --install-distro-source
			return 0
		;;
		''|--help)
			echo "syntax: DistroSourceTools.fn.sh <option>" >&2
			echo "syntax: DistroSourceTools.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				cat "$MMDAPP/.local/myx/myx.distro-source/sh-lib/HelpDistroSourceTools.text" >&2
			fi
			set +e ; return 1
		;;
		*)
			echo "ERROR: $MDSC_CMD: invalid option: $1" >&2
			set +e ; return 1
		;;
	esac
}

case "$0" in
	*/myx/myx.distro-source/sh-scripts/DistroSourceTools.fn.sh)

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DistroSourceTools.fn.sh --register-repository-root <repo-name>" >&2
			echo "syntax: DistroSourceTools.fn.sh --upgrade-source-tools" >&2
		fi

		set -e
		DistroSourceTools "$@"
	;;
esac
