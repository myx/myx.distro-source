[ -z "$MMDAPP" ] && echo '$MMDAPP' is not set! >&2 && exit 1

CompileCachedJavaProject(){
	local projectName="${1#$MMDAPP/source/}"
	if [ -z "$projectName" ] ; then
		echo "PrepareProjectSyncToCached: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	echo "Compiling project $projectName" >&2
	
	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-source \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/cached/sources" \
			--output-root "$MMDAPP/output" \
			--import-from-source \
			--project "$projectName" \
	)

	return 0

	rsync -azivC --exclude '*.class' --exclude '.*' --delete "$MMDAPP/cached/sources/$projectName/java/" "$MMDAPP/output/cached/$projectName/java"
	
	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-source \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/source" \
			--output-root "$MMDAPP/output" \
			--from-output \
			--project "$projectName" \
	)
}

case "$0" in
	*/sh-scripts/CompileCachedJavaProject.fn.sh) 
		# "$MMDAPP/source/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-from-cached
		
		CompileCachedJavaProject "$@"
	;;
esac