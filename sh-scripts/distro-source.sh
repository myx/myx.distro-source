#/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/DistroSourceCommand.fn.sh"

DistroSourceCommand \
	--output-root "$MMDAPP/output" \
	--source-root "${MDSC_SOURCE:-$MMDAPP/source}" \
	--cached-root "${MDSC_CACHED:-$MMDAPP/output/cached}" \
	"$@" \
	--print ''


exit 0

######################
######################
###
###   Examples:
###   Source:
###

# distro-source.sh --import-from-source --print-repositories --print ""
# distro-source.sh --import-from-source --print-projects --print ""
# distro-source.sh --import-from-source --select-project "myx/clean-boot" --print-provides --print ""
# distro-source.sh --import-from-source --print-provides --print ""

# distro-source.sh --import-from-source --select-project "myx/clean-boot" --print-selected --print ""


./distro/distro-source-prepare-output.command

./distro/distro-source.sh
./distro/distro-source.sh --import-from-source --print-projects

./distro/distro-source.sh --clean-output ../output -p ""

./distro/distro-source.sh -v --add-all-source-repositories ../source --print-repositories -p ""
./distro/distro-source.sh -v --add-all-source-repositories ../source --print-projects -p ""

./distro/distro-source.sh -v --add-source-repository ../source/myx --add-source-repository ../source/ndm --print-repositories -p ""
./distro/distro-source.sh -v --add-source-repository ../source/myx --add-remote-repository "ndm|https://myx.co.nz/distro/ndm" --print-repositories -p ""

./distro/distro-source.sh -v --add-all-source-repositories ../source  --prepare-build -p ""
./distro/distro-source.sh -v --import-from-source --prepare-build -p ""

./distro/distro-source.sh --import-from-source --prepare-sequence --select-all-from-source --print-selected

./distro/distro-source.sh --import-from-source --prepare-build --print '' --print-project-build-classpath ae3.sdk 
./distro/distro-source.sh --import-from-source --prepare-build --print '' --print-project-build-classpath myx.distro-deploy

./distro/distro-source.sh --import-from-source --prepare-build --print '' -vv --run-java-from-project myx.distro-deploy ru.myx.distro.MakePackagesFromFolders --done --print-project-build-classpath ae3.sdk 

./distro/distro-source.sh --import-from-source --prepare-build --select-all-from-source --print '' -vv --run-java-from-project myx.distro-deploy ru.myx.distro.MakePackagesFromFolders --done --print-project-build-classpath ae3.sdk 

./distro/distro-source.sh --import-from-source --prepare-build --select-all-from-source -vv --run-java-from-project myx.distro-deploy ru.myx.distro.MakePackagesFromFolders

./distro/distro-source.sh --import-from-source --prepare-build --select-all-from-source --make-packages-from-folders --sync-distro-from-cached

./distro/distro-source.sh --import-from-source --build-distro-from-sources
./distro/distro-source.sh --import-from-source --build-distro-from-sources -p ""


./distro/distro-source.sh -vv --run-java-from-project myx.distro-source ru.myx.distro.FolderScanCommand
