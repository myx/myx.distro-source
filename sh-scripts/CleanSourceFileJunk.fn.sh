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

	printf "🔍 Scanning for cleanup targets…\n"
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
		printf "🗑 Removing file: %s\n" "$f"
		rm -f "$f" && cleanup_count=$((cleanup_count+1))
	done

	# 2) Remove known junk dirs
	find "$ROOTPATH" -type d \( \
		-name '.Spotlight-V100' -o \
		-name '.Trashes' -o \
		-name '.AppleDouble' \
	\) ! -path '*/.git/*' -print0 \
	| while IFS= read -r -d '' d; do
		printf "📂 Removing dir: %s\n" "$d"
		rm -rf "$d" && cleanup_count=$((cleanup_count+1))
	done

	# 1) Pick your Attr‐tool only once
	while true; do
		if command -v xattr >/dev/null 2>&1; then
			probe_attr() { xattr -p "$1" "$2" >/dev/null 2>&1; }
			delete_attr() { xattr -d "$1" "$2" >/dev/null 2>&1; }
		elif command -v getfattr >/dev/null 2>&1 && command -v setfattr >/dev/null 2>&1; then
			probe_attr() { getfattr -n "user.$1" --only-values "$2" >/dev/null 2>&1; }
			delete_attr() { setfattr -x "user.$1" "$2" >/dev/null 2>&1; }
		else
			printf "📂 Extended attributes tool seems unavailable (no xattr or getfattr detected)" "$d"
			break
		fi

		# 3) Strip only unwanted xattrs
		#    List of Mac junk xattrs to remove:
		JUNK_XATTRS='
		com.apple.provenance
		com.apple.quarantine
		com.apple.ResourceFork
		com.apple.FinderInfo
		'

		if command -v xattr >/dev/null 2>&1; then
			# macOS / FreeBSD
			find "$ROOTPATH" ! -path '*/.git/*' -print0 \
			| while IFS= read -r -d '' file; do
				# list attrs for this file
				attrs="$(xattr "$file" 2>/dev/null)"
				for a in $attrs; do
					# check if it's in our junk list
					case " $JUNK_XATTRS " in
					*" $a "*) 
						printf "🧼 Stripping xattr %s from %s\n" "$a" "$file"
						xattr -d "$a" "$file" 2>/dev/null && cleanup_count=$((cleanup_count+1))
						;;
					esac
				done
			done
		fi
	done

	# 4) Summary
	if [ "$cleanup_count" -eq 0 ]; then
		echo "✅ Nothing to clean. Workspace is pristine."
	else
		printf "✨ Cleanup complete: %s items removed/cleaned.\n" "$cleanup_count"
	fi


	return 0


	echo "CleanAllOutputs: 🧻 Cleaning Output directories" >&2
	rm -rf "$MMDAPP"/{output,cached,export,distro}
	
	if type DistroSystemContext >/dev/null 2>&1 ; then
		echo "CleanAllOutputs: 🧹 Cleaning DistroShell in-line caches" >&2
		DistroSystemContext --uncache
	fi
}

case "$0" in
	*/sh-scripts/CleanSourceFileJunk.fn.sh) 
		CleanSourceFileJunk "$@"
	;;
esac
