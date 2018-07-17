#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi


. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroStatic.include"

DistroStatic "$@"



# Examples:
## Source:
### 
### 


# Old

# ./distro/distro-static.sh --print "SourceRoot:" --print-source-root --print "OutputRoot:" --print-output-root 

# ./distro/distro-static.sh --import-from-source --print-projects

# ./distro/distro-static.sh --import-from-source -p "**Projects:" --print-projects -p "**Provides:" --print-provides --prepare-sequence -p "**Sequence:" --print-sequence --prepare-build-index
# ./distro/distro-static.sh --import-from-source --print-provides
# ./distro/distro-static.sh --import-from-output --print-provides

# ./distro/distro-static.sh --import-from-source --prepare-build
# ./distro/distro-static.sh --import-from-source -v --prepare-build -p ""

# ./distro/distro-static.sh --import-from-distro --print-projects

# ./distro/distro-static.sh --import-from-distro -p "*Repos:" --print-repositories -p "*Projects:" --print-projects
# ./distro/distro-static.sh --import-from-source -p "*Repos:" --print-repositories -p "*Projects:" --print-projects
# ./distro/distro-static.sh --import-from-output -p "*Repos:" --print-repositories -p "*Projects:" --print-projects


# ./distro/distro-static.sh --import-from-source --prepare-build --select-project ae3/ae3.sdk.base --select-required --print-selected --build --build-repository ndm --build-all
# ./distro/distro-static.sh --import-from-source --select-project ae3/ae3.sdk.base --select-required --print-selected
# ./distro/distro-static.sh --import-from-output --select-project ae3/ae3.sdk.base --select-required --print-selected

# ./distro/distro-static.sh --import-from-source --prepare-sequence --print-sequence
# ./distro/distro-static.sh --import-from-output --prepare-sequence --print-sequence

# ./distro/distro-static.sh -v --import-from-source --build-all --make-distro -p ""

# ./distro/distro-static.sh --add-remote-repository "myx|http://myx.ru/distro" -p "*Repos:" --print-repositories --process-repositories -p "*Projects:" --print-projects

# ./distro/distro-static.sh --exec-sync --source /tmp/aaa/src1 --target /tmp/aaa/tgt --do-sync-continue-always --print-updates --done --print-projects

# ./distro/distro-static.sh -v --clean-output ../output -p ""
