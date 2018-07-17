
if [ "`type -t SyncSourceRepositoryToCached`" != "function" ] ; then
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/SyncSourceRepositoryToCached.fn.sh"
fi
if [ "`type -t DistroSourceCommand`" != "function" ] ; then
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/DistroSourceCommand.fn.sh"
fi

PrepareBuildDependencyIndex(){
	mkdir -p "$MMDAPP/output/distro"
	
	( \
		DistroSourceCommand \
			-v \
			--source-root "$MMDAPP/cached/sources" \
			--output-root "$MMDAPP/output" \
			--import-from-source --select-all-from-source \
			--print ''  -vv \
			--build-all \
			--print '' \
	)
}

PrepareBuildDependencyIndex

