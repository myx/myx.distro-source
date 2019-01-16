#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

ListDistroScripts(){
	case "$1" in
		--completion)
			shift
			( \
				ListDistroScripts "$@" ; \
			) | sort | uniq | sed 's:\.fn\.sh$::' 
			return 0
			;;
		--all)
			shift
			local FILTER="$MMDAPP/source/"
			case "$MDSC_OPTION" in
				--distro-from-distro)
					local MDPATH="$MMDAPP/source/myx/myx.distro-deploy/sh-scripts $MMDAPP/source/myx/myx.distro-source/sh-scripts"
				;;
				--distro-from-output)
					local MDPATH="$MMDAPP/source/myx/myx.distro-deploy/sh-scripts $MMDAPP/source/myx/myx.distro-source/sh-scripts"
				;;
				*)
					local MDPATH="$MMDAPP/source/myx/myx.distro-source/sh-scripts $MMDAPP/source/myx/myx.distro-deploy/sh-scripts"
				;;
			esac
			;;
		--type)
			shift
			local MDTYPE="$1" ; shift
			local MDPATH="$MMDAPP/source/myx/myx.distro-$MDTYPE/sh-scripts"
			if [ ! -d "$MDPATH" ] ; then
				echo "ListDistroScripts: invalid type: $MDTYPE" >&2
				return 1
			fi
			local FILTER="$MDPATH/"
			;;
		*)
			local MDPATH="$MMDAPP/source/myx/myx.distro-source/sh-scripts"
			local FILTER="$MDPATH/"
			;;
	esac
	find \
			$MDPATH \
			 -type 'f' -name '*.sh' \
		| sed "s:^$FILTER::g" | sort
}

case "$0" in
	*/sh-scripts/ListDistroScripts.fn.sh) 
		ListDistroScripts "$@"
	;;
esac