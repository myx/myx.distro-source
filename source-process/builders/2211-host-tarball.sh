type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"
Require ListDistroProvides

#[ -n "${TAR_ARGS_GENERIC-}" ] || \
#	. "${MYXROOT:-/usr/local/share/myx.common}/bin/lib/tar.${MYXUNIX:-$( uname -s )}"

[ -n "${TAR_ARGS_GENERIC-}" ] || \
TAR_ARGS_GENERIC=$( printf '%s ' \
	--format=posix \
	--no-xattrs \
	$(if tar --version 2>/dev/null | grep -q GNU; then
		echo --no-acls --no-selinux
	fi) \
	$(if tar --version 2>/dev/null | grep -qi bsdtar; then
		echo --disable-copyfile \
			$( [ "$(uname -s)" != FreeBSD ] || echo --no-mac-metadata )
	fi) \
	--exclude='.DS_Store' \
	--exclude='.AppleDouble' \
	--exclude='Icon?' \
	--exclude='._*' \
	--exclude='.Spotlight-V100' \
	--exclude='.Trashes' \
	--exclude='.git' \
	--exclude='.git/**' \
	--exclude='CVS'
)

CheckMakeProjectHostTarball(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "CheckMakeProjectHostTarball: '⛔ ERROR: projectName' argument is required!" >&2 ; return 1
	fi
	
	local SRC="$MDSC_SOURCE/$projectName"
	
	if [ -d "$SRC/host/tarball" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/$projectName"
		local PACK_ROOT="`basename "$projectName"`"
		mkdir -p "$BUILT_DIR"
		
		( \
			cd "$SRC/.." ; \
			tar -cvjf "$BUILT_DIR/host-tarball.tbz" \
				${TAR_ARGS_GENERIC-} \
				$( [ ! -d "$SRC/host-freebsd/tarball" ] || echo "$PACK_ROOT/host-freebsd/tarball" ) \
				$( [ ! -d "$SRC/host-macosx/tarball" ]  || echo "$PACK_ROOT/host-macosx/tarball" ) \
				$( [ ! -d "$SRC/host-ubuntu/tarball" ]  || echo "$PACK_ROOT/host-ubuntu/tarball" ) \
				"$PACK_ROOT/host/tarball"
		)
	 
	 
		echo done.
	fi
}

ListDistroProvides --select-changed --filter-and-cut "source-process" \
| grep -e " host-tarball.tbz$" \
| cut -d" " -f1 \
| sort -u \
| Parallel Prefix -2 CheckMakeProjectHostTarball # "$projectName" 
