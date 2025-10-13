#!/usr/bin/env bash
# ^^^ for syntax checking in the editor only

: "${MMDAPP:?⛔ ERROR: MMDAPP is not set}"

CompileCachedJavaRepository(){
	REPO_NAME=$1; shift
	REPO_JAVA="$MMDAPP/.local/output-cache/$REPO_NAME"

	echo "Compiling repository $REPO_NAME" >&2


	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-source \
			ru.myx.distro.prepare.MakeCompileSources \
			--cached-root "$MMDAPP/.local/source-cache/prepare" \
			--source-root "$MMDAPP/.local/source-cache/sources" \
			--output-root "$MMDAPP/.local/output-cache" \
			--repository "$REPO_NAME" \
	)
}

case "$0" in
	*/sh-scripts/CompileCachedJavaRepository.fn.sh) 
		# "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/distro-source.sh" --clean-output "$MMDAPP/output" --print ""
		CompileCachedJavaRepository "$@"
	;;
esac
