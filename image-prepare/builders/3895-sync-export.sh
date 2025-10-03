SyncExportsFromOutput(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: SyncExportsFromOutput: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local SRC="$2"
	if [ -z "$SRC" ] ; then
		echo "⛔ ERROR: SyncExportsFromOutput: 'SRC' argument is required!" >&2 ; return 1
	fi
	
	local DST="$3"
	if [ -z "$DST" ] ; then
		echo "⛔ ERROR: SyncExportsFromOutput: 'DST' argument is required!" >&2 ; return 1
	fi
	
	local SOURCE_DIR="$MDSC_SOURCE/$projectName"
	local CACHED_DIR="$MDSC_CACHED/$projectName"

	local EXPORT_DST="$MMDAPP/output/export/$DST"

	if [ "0" = "1" ] && [ -f "$EXPORT_DST" ] ; then
		if [ -z "$BUILD_STAMP" ] || [ ! "$BUILD_STAMP" -gt "`date -u -r "$EXPORT_DST" "+%Y%m%d%H%M%S"`" ] ; then
			echo "SyncExportsFromOutput: "$SRC" skipped, present and fresh"
			return 0
		fi
		if [ -e "$SOURCE_DIR/$SRC" ] && [ "$SOURCE_DIR/$SRC" -ot "$EXPORT_DST" ] ; then
			echo "SyncExportsFromOutput: "$SRC" skipped, present and up to date"
			return 0
		fi
	fi

	if test -e "$CACHED_DIR/$SRC" ; then
		printf 'sync-export: %s %s (cached) \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2
		mkdir -p "`dirname "$EXPORT_DST"`"
		rsync -ai --delete "$CACHED_DIR/$SRC" "$EXPORT_DST" 2>&1 \
		| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || :)
		return 0
	fi

	if test -e "$SOURCE_DIR/$SRC" ; then
		printf 'sync-export: %s %s (source) \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2
		mkdir -p "`dirname "$EXPORT_DST"`"
		rsync -ai --delete "$SOURCE_DIR/$SRC" "$EXPORT_DST" 2>&1 \
		| (grep -v --line-buffered -E '>f\.\.t\.+ ' >&2 || :)
		return 0
	fi

	echo "⛔ ERROR: export file not found: $SRC" 
}

Require ListDistroProvides
ListDistroProvides --select-changed --filter-and-cut "deploy-export" | sed "s|:| |g" | while read -r projectName sourceName targetName ; do
	SyncExportsFromOutput "$projectName" "$sourceName" "$targetName"
done
