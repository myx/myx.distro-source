Require ListChangedSourceProjects

CheckMakeProjectDataFolder(){
	local PKG="$1"
	local CHECK_DIR="$MDSC_SOURCE/$PKG/data"
	if [ -d "$CHECK_DIR" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/$PKG"
		mkdir -p "$BUILT_DIR"
		tar -cvj -C "$CHECK_DIR" -f "$BUILT_DIR/data.tbz" "./"
	fi
}

for PKG in $( ListChangedSourceProjects ) ; do
	Async "`basename "$PKG"`" CheckMakeProjectDataFolder "$PKG"
	wait
done
