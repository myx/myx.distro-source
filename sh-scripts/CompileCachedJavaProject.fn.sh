#!/usr/bin/env bash
# ^^^ for syntax checking in the editor only

: "${MMDAPP:?⛔ ERROR: MMDAPP is not set}"

CompileCachedJavaProject(){

	local MDSC_CMD='CompileCachedJavaProject'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2
	
	local projectName="${1#$MDSC_SOURCE/}"
	case "$projectName" in
	'')
		echo "⛔ ERROR: $MDSC_CMD: 'projectName' argument is required!" >&2
		set +e ; return 1
	;;
	--project-from-env)
		projectName="$MDSC_PRJ_NAME" ; [ -n "$projectName" ] || {
			echo "⛔ ERROR: $MDSC_CMD: --project-from-env: MDSC_PRJ_NAME is not set!" >&2
			set +e ; return 1
		}
	;;
	'.'|--project-from-pwd)
		projectName="$( Distro ListDistroProjects --project '.' )" ; [ -n "$projectName" ] || {
			echo "⛔ ERROR: $MDSC_CMD: --project-from-pwd: can't map working directory to project: $(pwd)" >&2
			set +e ; return 1
		}
	;;
	esac
	[ -f "$MDSC_SOURCE/$projectName/project.inf" ] || {
		echo "⛔ ERROR: $MDSC_CMD: project is invalid or unknown: $projectName" >&2
		set +e ; return 1
	}
	shift
	
	echo "$MDSC_CMD: Compiling project $projectName" >&2
	
	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-system \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/.local/source-cache/sources" \
			--output-root "$MMDAPP/.local/output-cache/process" \
			--import-from-source \
			--project "$projectName" \
	)

	return 0

	rsync -azivC --exclude '*.class' --exclude '.*' --delete "$MMDAPP/.local/source-cache/sources/$projectName/java/" "$MMDAPP/.local/output-cache/$projectName/java" 2>&1 \
	| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || :)
	
	( \
		. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/RunJavaClassSource.include" ;
		RunJavaClassSource \
			myx/myx.distro-system \
			ru.myx.distro.prepare.MakeCompileSources \
			--source-root "$MMDAPP/.local/source-cache/sources" \
			--output-root "$MMDAPP/.local/output-cache" \
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
