#!/bin/sh
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

	# sub-shell, cd
	(
		cd "$ROOTPATH" || ( echo "⛔ ERROR: can't change dir: $ROOTPATH" >&2 && exit 1 )

		local cleanup_count=0

		# 1) Remove known junk files (skip .git)
		find . -type f \( \
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
		find . -type d \( \
			-name '.Spotlight-V100' -o \
			-name '.Trashes' -o \
			-name '.AppleDouble' \
		\) ! -path '*/.git/*' -print0 \
		| while IFS= read -r -d '' d; do
			printf "CleanSourceFileJunk: 📂 Removing dir: %s\n" "$d"
			rm -rf "$d" && cleanup_count=$((cleanup_count+1))
		done


		local args attrs delflags f name
		local JUNK_NAMES="com.apple.provenance com.apple.quarantine com.apple.ResourceFork com.apple.FinderInfo"

		# 1) Detect which xattr tool we have
		if command -v xattr >/dev/null 2>&1; then

			echo "CleanSourceFileJunk: 🔍 Stripping junk attributes with 'xattr' @ $ROOTPATH"

			# mac/bsd: build -e ^NAME$ args for grep
			args=""
			for name in $JUNK_NAMES; do
				args="$args -e '^${name}\$'"
			done

			# build deletion flags in one shot
			for name in $attrs; do
				delflags="$delflags -d $name"
			done

			find . ! -path '*/.git/*' -print0 \
			| while IFS= read -r -d '' f; do
 				attrs=$(xattr "$f" 2>/dev/null | grep "$args") || continue
				[ -z "$attrs" ] && continue

				printf "CleanSourceFileJunk: 🧼 Removing [%s] from %s\n" "$attrs" "$f" >&2
				if xattr $delflags -- "$f" ; then
					cleanup_count=$((cleanup_count+1))
				else
					printf "CleanSourceFileJunk: ⚠️ Failed to remove [%s] from %s (exit %d)\n" "$attrs" "$file" "$?" >&2
				fi
			done

		elif command -v getfattr >/dev/null 2>&1 && command -v setfattr >/dev/null 2>&1; then

			echo "CleanSourceFileJunk: 🔍 Stripping junk attributes with 'getfattr' @ $ROOTPATH"

			# linux: build -n user.NAME args for xfattr
			args=""
			for name in $JUNK_NAMES; do
				args="$args -n user.$name"
			done
			# build deletion flags in one shot
			delflags=""
			for name in $attrs; do
				delflags="$delflags -x $name"
			done

			find . ! -path '*/.git/*' -print0 \
			| while IFS= read -r -d '' f; do
				attrs=$(getfattr $args --only-names "$f" 2>/dev/null) || continue
				[ -z "$attrs" ] && continue

				printf "CleanSourceFileJunk: 🧼 Removing [%s] from %s\n" "$attrs" "$f"
				if setfattr $delflags "$f" ; then
					cleanup_count=$((cleanup_count+1))
				else
					printf "CleanSourceFileJunk: ⚠️ Failed to remove [%s] from %s (exit %d)\n" "$attrs" "$file" "$?" >&2
				fi
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
	)
}

case "$0" in
	*/sh-scripts/CleanSourceFileJunk.fn.sh) 
		CleanSourceFileJunk "$@"
	;;
esac
