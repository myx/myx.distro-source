#!/usr/bin/env bash
# ^^^ for syntax checking in the editor only

: "${MMDAPP:?⛔ ERROR: MMDAPP is not set}"

CompileCachedJavaRepository(){
	REPO_NAME=$1; shift
	REPO_JAVA="$MMDAPP/output/cached/$REPO_NAME"

	echo "Compiling repository $REPO_NAME" >&2


	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-source \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/source" \
			--output-root "$MMDAPP/output" \
			--repository "$REPO_NAME" \
	)
}

case "$0" in
	*/sh-scripts/CompileCachedJavaRepository.fn.sh) 
		# "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""
		CompileCachedJavaRepository "$@"
	;;
esac
