MakeProjectSourceArchive(){
	local projectName="${1#$MMDAPP/source/}"
	[ -z "$projectName" ] && echo "⛔ ERROR: MakeProjectSourceArchive: 'projectName' argument is required!" >&2 && return 1
	
	local CHECK_DIR="$MDSC_SOURCE/$projectName"
	local BUILT_DIR="$MDSC_OUTPUT/$projectName"
	local BASE_ROOT="`dirname "$CHECK_DIR"`"
	local PACK_ROOT="`basename "$CHECK_DIR"`"
	mkdir -p "$BUILT_DIR"
	tar -zcvf "$BUILT_DIR/project-source.tgz" \
		--format=posix \
		--exclude='.DS_Store' \
		--exclude='.AppleDouble' \
		--exclude='Icon?' \
		--exclude='._*' \
		--exclude='.Spotlight-V100' \
		--exclude='.Trashes' \
		--exclude='.git' \
		--exclude='.git/**' \
		--exclude='CVS' \
		$( if tar --version 2>/dev/null | grep -q GNU ; then
			echo --no-xattrs --no-acls --no-selinux
		fi ) \
		$( if tar --version 2>/dev/null | grep -qi bsdtar ; then 
			echo --disable-copyfile $( [ "$(uname)" != FreeBSD ] || echo --no-mac-metadata )
		fi ) \
		-C "$BASE_ROOT" \
		"$PACK_ROOT"
}

Require ListDistroProvides
ListDistroProvides --select-changed --filter-and-cut "source-process" | grep -e " project-source.tgz$" | cut -d" " -f1 | sort -u | while read -r projectName ; do
	Async "`basename "$projectName"`" MakeProjectSourceArchive "$projectName"
	wait
done
