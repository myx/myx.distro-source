Require ListChangedSourceProjects
Require ListProjectProvides

CompileJavaSources(){
	local PKG="$1"
	if [ -z "$PKG" ] ; then
		echo "MakeProjectSourceArchive: 'PKG' argument is required!" >&2 ; exit 1
	fi

	( \
		. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/CompileCachedJavaProject.fn.sh" ; \
		CompileCachedJavaProject $PKG \
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

 
for PKG in $( ListChangedSourceProjects ) ; do
	if [ ! -z "$( ListProjectProvides "$PKG" "source-process" | grep -e "^compile-java$" )" ] ; then
		Async "`basename "$PKG"`" CompileJavaSources "$PKG"
		wait
	fi
done
