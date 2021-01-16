#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi


Help(){
	echo "Syntax:" >&2
	echo "	Action <distroCommand>" >&2
	echo "	Distro <distroCommand>" >&2
	echo "	Deploy <distroCommand>" >&2
	if [ "$1" = "--all" ] || [ "$1" = "--help" ] ; then
		echo "	Require <distroCommandName>" >&2
		echo "	#SetEnv <exportVariableName> <command>[ <args...>]" >&2
		echo "	#SetVar <normalVariableName> <command>[ <args...>]" >&2
		echo "	#SetLcl <localVariableName> <command>[ <args...>]" >&2
	fi
}

case "$0" in
	*/sh-scripts/Help.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		
		Help "$@"
	;;
esac