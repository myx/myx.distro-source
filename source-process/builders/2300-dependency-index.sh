
# Require PrepareRepositorySyncToCached
Require DistroSourceCommand

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

