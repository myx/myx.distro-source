Require ListChangedSourceProjects
Require ListProjectProvides

CheckMakeProjectHostTarball(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "CheckMakeProjectHostTarball: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local SRC="$MDSC_SOURCE/$projectName"
	
	if [ -d "$SRC/host/tarball" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/$projectName"
		local PACK_ROOT="`basename "$projectName"`"
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

for projectName in $( ListChangedSourceProjects ) ; do
	if test ! -z "$( ListProjectProvides "$projectName" "source-process" | grep -e "^host-tarball.tbz$" )" ; then
		Async "`basename "$projectName"`" CheckMakeProjectHostTarball "$projectName"
		wait
	fi
done
