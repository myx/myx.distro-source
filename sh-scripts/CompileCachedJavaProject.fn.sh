#!/usr/bin/env bash
# ^^^ for syntax checking in the editor only

: "${MMDAPP:?⛔ ERROR: MMDAPP is not set}"

CompileCachedJavaProject(){

	local MDSC_CMD='CompileCachedJavaProject'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	local projectName="${1#$MMDAPP/source/}"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	fi
	
	echo "$MDSC_CMD: Compiling project $projectName" >&2
	
	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-source \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/cached/sources" \
			--output-root "$MMDAPP/output" \
			--import-from-source \
			--project "$projectName" \
	)

	return 0

	rsync -azivC --exclude '*.class' --exclude '.*' --delete "$MMDAPP/cached/sources/$projectName/java/" "$MMDAPP/output/cached/$projectName/java" 2>&1 \
	| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || true)
	
	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
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
		# "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""

		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-from-cached
		
		CompileCachedJavaProject "$@"
	;;
esac
