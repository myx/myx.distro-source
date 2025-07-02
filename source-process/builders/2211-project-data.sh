Require ListChangedSourceProjects

CheckMakeProjectDataFolder(){
	local PKG="$1"
	local CHECK_DIR="$MDSC_SOURCE/$PKG/data"
	if [ -d "$CHECK_DIR" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/$PKG"
		mkdir -p "$BUILT_DIR"
		tar -cvjf "$BUILT_DIR/data.tbz" \
			--format=ustar \
			--exclude='.DS_Store' \
			--exclude='.AppleDouble' \
			--exclude='Icon?' \
			--exclude='._*' \
			--exclude='.Spotlight-V100' \
			--exclude='.Trashes' \
			--exclude='.git' \
			--exclude='.git/**' \
			--exclude='CVS' \
			$( if tar --version 2>/dev/null | grep -q GNU ; then echo "--no-xattrs --no-acls --no-selinux"; fi ) \
			$( if tar --version 2>/dev/null | grep -qi bsdtar ; then echo "--disable-copyfile"; fi ) \
			-C "$CHECK_DIR" \
			"./"
	fi
}

ListChangedSourceProjects | while read -r PKG ; do
	Async "`basename "$PKG"`" CheckMakeProjectDataFolder "$PKG"
	wait
done
