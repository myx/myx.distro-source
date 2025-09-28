#!/usr/bin/env bash
# ^^^ for syntax checking in the editor only

CompileJavaSources(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: MakeProjectSourceArchive: 'projectName' argument is required!" >&2 ; return 1
	fi

	( \
		Distro CompileCachedJavaProject $projectName \
	)
	
	return 0
	
	( \
		Distro DistroSourceCommand \
			-v$( 
				[ -z "$MDSC_DETAIL" ] || printf 'v' 
			) \
			--output-root "$MMDAPP/output" \
			--source-root "$MMDAPP/.local/source-cache/sources" \
			--cached-root "$MMDAPP/output/cached" \
			--import-from-source --select-all-from-source \
			--prepare-build-roots --prepare-build-distro-index --prepare-build-compile-index \
			--print '' \
	)
}

type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"

Distro ListDistroProvides --select-changed --filter-and-cut "source-process" \
| { grep -e " compile-java$" || [ $? -eq 1 ] ; } \
| cut -d" " -f1 \
| sort -u \
| Parallel Prefix -2 CompileJavaSources # "$projectName"
