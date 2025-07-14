MakeProjectSourceArchive(){
	local projectName="${1#$MMDAPP/source/}"
	[ -z "$projectName" ] && echo "⛔ ERROR: MakeProjectSourceArchive: 'projectName' argument is required!" >&2 && return 1
	
	local CHECK_DIR="$MDSC_SOURCE/$projectName"
	local BUILT_DIR="$MDSC_OUTPUT/$projectName"
	local BASE_ROOT="`dirname "$CHECK_DIR"`"
	local PACK_ROOT="`basename "$CHECK_DIR"`"
	mkdir -p "$BUILT_DIR"
	tar -czvf "$BUILT_DIR/project-source.tgz" \
		--format=posix \
		--no-xattrs \
		$( if tar --version 2>/dev/null | grep -q GNU ; then
			echo --no-acls --no-selinux
		fi ) \
		$( if tar --version 2>/dev/null | grep -qi bsdtar ; then 
			echo --disable-copyfile $( [ "$(uname)" != FreeBSD ] || echo --no-mac-metadata )
		fi ) \
		--exclude='.DS_Store' \
		--exclude='.AppleDouble' \
		--exclude='Icon?' \
		--exclude='._*' \
		--exclude='.Spotlight-V100' \
		--exclude='.Trashes' \
		--exclude='.git' \
		--exclude='.git/**' \
		--exclude='CVS' \
		-C "$BASE_ROOT" \
		"$PACK_ROOT"
}

type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"
Require ListDistroProvides

ListDistroProvides --select-changed --filter-and-cut "source-process" \
| grep -e " project-source.tgz$" \
| cut -d" " -f1 \
| sort -u \
| Parallel Prefix -2 MakeProjectSourceArchive # "$projectName"
