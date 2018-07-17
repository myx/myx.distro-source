Require ListChangedSourceProjects
Require ListProjectProvides

CheckMakeProjectHostTarball(){
	local PKG="$1"
	if [ -z "$PKG" ] ; then
		echo "CheckMakeProjectHostTarball: 'PKG' argument is required!" >&2 ; exit 1
	fi
	
	local SRC="$MDSC_SOURCE/$PKG"
	
	if [ -d "$SRC/host/tarball" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/$PKG"
		local PACK_ROOT="`basename "$PKG"`"
		mkdir -p "$BUILT_DIR"
		
		( \
			cd "$SRC/.." ; \
			tar -cvj \
				-f "$BUILT_DIR/host-tarball.tbz" \
				` [ ! -d "$SRC/host-freebsd/tarball" ] || echo "$PACK_ROOT/host-freebsd/tarball" ` \
				` [ ! -d "$SRC/host-macosx/tarball" ]  || echo "$PACK_ROOT/host-macosx/tarball" ` \
				` [ ! -d "$SRC/host-ubuntu/tarball" ]  || echo "$PACK_ROOT/host-ubuntu/tarball" ` \
				"$PACK_ROOT/host/tarball"
		)
	 
	 
		echo done.
	fi
}

for PKG in $( ListChangedSourceProjects ) ; do
	if test ! -z "$( ListProjectProvides "$PKG" "source-process" | grep -e "^host-tarball.tbz$" )" ; then
		Async "`basename "$PKG"`" CheckMakeProjectHostTarball "$PKG"
		wait
	fi
done
