#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi




# delete macOS junk files & dirs, and only remove unwanted xattrs
CleanSourceFileJunk(){
	# myx.common remove/fileJunk --verbose "${1:-$MMDAPP/}"

	local ROOTPATH="${1:-"$MMDAPP/source"}"

	printf "CleanSourceFileJunk: 🔍 Scanning for junk files @ $ROOTPATH\n"
	cleanup_count=0

	# 1) Remove known junk files (skip .git)
	find "$ROOTPATH" -type f \( \
		-name '.DS_Store' -o \
		-name '._*' -o \
		-name '.AppleDouble' -o \
		-name 'Icon?' -o \
		-name '.Trashes' \
	\) ! -path '*/.git/*' -print0 \
	| while IFS= read -r -d '' f; do
		printf "CleanSourceFileJunk: 🗑 Removing file: %s\n" "$f"
		rm -f "$f" && cleanup_count=$((cleanup_count+1))
	done

	# 2) Remove known junk dirs
	find "$ROOTPATH" -type d \( \
		-name '.Spotlight-V100' -o \
		-name '.Trashes' -o \
		-name '.AppleDouble' \
	\) ! -path '*/.git/*' -print0 \
	| while IFS= read -r -d '' d; do
		printf "CleanSourceFileJunk: 📂 Removing dir: %s\n" "$d"
		rm -rf "$d" && cleanup_count=$((cleanup_count+1))
	done



	# 1) Detect which xattr tool we have
	if command -v xattr >/dev/null 2>&1; then
		# Regexp matching exactly the names you care about
		local JUNK_RX='^(com\.apple\.provenance|com\.apple\.quarantine|com\.apple\.ResourceFork|com\.apple\.FinderInfo)$'
		echo "CleanSourceFileJunk: 🔍 Stripping junk attributes with 'xattr' @ $ROOTPATH"

		local attrs f
		find "$ROOTPATH" ! -path '*/.git/*' -print0 \
		| while IFS= read -r -d '' f; do
			# list only the junk attributes
			attrs=$(xattr -l "$f" 2>/dev/null | cut -d: -f1 | grep -E "$JUNK_RX" || :)

			[ -z "$attrs" ] && continue

			# log and delete them in one go
			printf "🧼 Removing [%s] from %s\n" "$attrs" "$f"
			printf "%s\n" "$attrs" | xargs -I{} xattr -d {} "$f"
			cleanup_count=$((cleanup+1))
		done

	elif command -v getfattr >/dev/null 2>&1 && command -v setfattr >/dev/null 2>&1; then
		local NAMES="com.apple.provenance com.apple.quarantine com.apple.ResourceFork com.apple.FinderInfo"
		echo "CleanSourceFileJunk: 🔍 Stripping junk attributes with 'getfattr' @ $ROOTPATH"

		local args attrs delflags f
		find "$ROOTPATH" ! -path '*/.git/*' -print0 \
		| while IFS= read -r -d '' f; do

			# linux: build -n user.NAME args
			args=""
			for name in $NAMES; do
			args="$args -n user.$name"
			done

			# probe only those names
			attrs=$(getfattr $args --only-names "$f" 2>/dev/null || :)

			[ -z "$attrs" ] && continue

			# build deletion flags in one shot
			delflags=""
			for a in $attrs; do
			delflags="$delflags -x $a"
			done

			printf "🧼 Removing [%s] from %s\n" "$attrs" "$f"
			setfattr $delflags "$f"
			cleanup_count=$((cleanup+1))
		done
	else
		printf "CleanSourceFileJunk: 📂 Extended attributes tool seems unavailable (no xattr or getfattr detected)" "$d"
	fi

	# 4) Summary
	if [ "$cleanup_count" -eq 0 ]; then
		echo "CleanSourceFileJunk: ✅ Nothing to clean. Workspace is pristine."
	else
		printf "CleanSourceFileJunk: ✨ Cleanup complete: %s items removed/cleaned.\n" "$cleanup_count"
	fi
}

case "$0" in
	*/sh-scripts/CleanSourceFileJunk.fn.sh) 
		CleanSourceFileJunk "$@"
	;;
esac
