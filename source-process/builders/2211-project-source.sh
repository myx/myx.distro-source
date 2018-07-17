Require ListChangedSourceProjects
Require ListProjectProvides

MakeProjectSourceArchive(){
	local PKG="${1#$MMDAPP/source/}"
	if [ -z "$PKG" ] ; then
		echo "MakeProjectSourceArchive: 'PKG' argument is required!" >&2 ; exit 1
	fi
	
	local CHECK_DIR="$MDSC_SOURCE/$PKG"
	local BUILT_DIR="$MDSC_OUTPUT/$PKG"
	local BASE_ROOT="`dirname "$CHECK_DIR"`"
	local PACK_ROOT="`basename "$CHECK_DIR"`"
	mkdir -p "$BUILT_DIR"
	tar -zcv -C "$BASE_ROOT" -f "$BUILT_DIR/project-source.tgz" "$PACK_ROOT"
}

for PKG in $( ListChangedSourceProjects ) ; do
	if test ! -z "$( ListProjectProvides "$PKG" "source-process" | grep -e "^project-source.tgz$" )" ; then
		Async "`basename "$PKG"`" MakeProjectSourceArchive "$PKG"
		wait
	fi
done
