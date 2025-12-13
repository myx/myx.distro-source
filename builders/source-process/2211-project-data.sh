#!/bin/sh
# ^^^ for syntax highlight

[ full != "$MDSC_DETAIL" ] || set -x

type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"
Require ListChangedSourceProjects

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

CheckMakeProjectDataFolder(){
	local PKG="$1"
	local CHECK_DIR="$MDSC_SOURCE/$PKG/data"
	if [ -d "$CHECK_DIR" ] ; then
		local BUILT_DIR="$MDSC_OUTPUT/distro/$PKG"
		mkdir -p "$BUILT_DIR"
		tar -cvjf "$BUILT_DIR/data.tbz" \
			${TAR_ARGS_GENERIC-} \
			-C "$CHECK_DIR" \
			"./"
	fi
}

ListChangedSourceProjects \
| Parallel Prefix -2 CheckMakeProjectDataFolder # "$projectName" 
