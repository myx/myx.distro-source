Require ListChangedSourceProjects
Require ListProjectProvides

MakeProjectSourceArchive(){
	local projectName="${1#$MMDAPP/source/}"
	[ -z "$projectName" ] && echo "MakeProjectSourceArchive: 'projectName' argument is required!" >&2 && return 1
	
	local CHECK_DIR="$MDSC_SOURCE/$projectName"
	local BUILT_DIR="$MDSC_OUTPUT/$projectName"
	local BASE_ROOT="`dirname "$CHECK_DIR"`"
	local PACK_ROOT="`basename "$CHECK_DIR"`"
	mkdir -p "$BUILT_DIR"
	tar -zcv -C "$BASE_ROOT" -f "$BUILT_DIR/project-source.tgz" "$PACK_ROOT"
}

for projectName in $( ListChangedSourceProjects ) ; do
	if test ! -z "$( ListProjectProvides "$projectName" "source-process" | grep -e "^project-source.tgz$" )" ; then
		Async "`basename "$projectName"`" MakeProjectSourceArchive "$projectName"
		wait
	fi
done
