#!/bin/sh

type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"
Require ListDistroProvides

CompileJavaSources(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: MakeProjectSourceArchive: 'projectName' argument is required!" >&2 ; return 1
	fi

	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/CompileCachedJavaProject.fn.sh" ; \
		CompileCachedJavaProject $projectName \
	)
	
	return 0
	
	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/DistroSourceCommand.fn.sh" ; \
		DistroSourceCommand \
			-v \
			--output-root "$MMDAPP/output" \
			--source-root "$MMDAPP/.local/source-cache/sources" \
			--cached-root "$MMDAPP/output/cached" \
			--import-from-source --select-all-from-source \
			--prepare-build-roots --prepare-build-distro-index --prepare-build-compile-index \
			--print '' \
	)
}



ListDistroProvides --select-changed --filter-and-cut "source-process" \
| grep -e " compile-java$" \
| cut -d" " -f1 \
| sort -u \
| Parallel Prefix -2 CompileJavaSources # "$projectName"
