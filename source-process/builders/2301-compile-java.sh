CompileJavaSources(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "MakeProjectSourceArchive: 'projectName' argument is required!" >&2 ; return 1
	fi

	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/CompileCachedJavaProject.fn.sh" ; \
		CompileCachedJavaProject $projectName \
	)
	
	return 0
	
	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/DistroSourceCommand.fn.sh" ; \
		DistroSourceCommand \
			-v \
			--output-root "$MMDAPP/output" \
			--source-root "$MMDAPP/cached/sources" \
			--cached-root "$MMDAPP/output/cached" \
			--import-from-source --select-all-from-source \
			--prepare-build-roots --prepare-build-distro-index --prepare-build-compile-index \
			--print '' \
	)
}



Require ListDistroProvides
ListDistroProvides --select-changed --filter-and-cut "source-process" | grep -e " compile-java$" | cut -d" " -f1 | sort | uniq | while read -r projectName ; do
	Async "`basename "$projectName"`" CompileJavaSources "$projectName"
	wait
done
