Require ListChangedSourceProjects
Require ListProjectProvides

SyncExportsFromCached(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "SyncExportsFromCached: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local SRC="$2"
	if [ -z "$SRC" ] ; then
		echo "SyncExportsFromCached: 'SRC' argument is required!" >&2 ; return 1
	fi
	
	local DST="$3"
	if [ -z "$DST" ] ; then
		echo "SyncExportsFromCached: 'DST' argument is required!" >&2 ; return 1
	fi
	
	local SOURCE_DIR="$MDSC_SOURCE/$projectName"
	local TARGET_DIR="$MDSC_OUTPUT/$projectName"

	if [ -f "$TARGET_DIR/$SRC" ] ; then
		if [ -z "$BUILD_STAMP" ] || [ "$BUILD_STAMP" -lt "`date -u -r "$TARGET_DIR/$SRC" "+%Y%m%d%H%M%S"`" ] ; then
			echo "SyncExportsFromCached: "$SRC" skipped, present and fresh"
			return 0
		fi
		if [ -e "$SOURCE_DIR/$SRC" ] && [ "$SOURCE_DIR/$SRC" -ot "$TARGET_DIR/$SRC" ] ; then
			echo "SyncExportsFromCached: "$SRC" skipped, present and up to date"
			return 0
		fi
	fi
	
	if test -e "$SOURCE_DIR/$SRC" ; then
		printf 'sync-export: %s %s (src) \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2
		mkdir -p "`dirname "$TARGET_DIR/$SRC"`"
		rsync -ai --delete "$SOURCE_DIR/$SRC" "$TARGET_DIR/$SRC"
		return 0
	fi
	
	echo "ERROR: export file not found: $SRC" 
}

local projectName
for projectName in $( ListChangedSourceProjects ) ; do
	for ITEM in $( ListProjectProvides "$projectName" "deploy-export" ) ; do
		SyncExportsFromCached "$projectName" $( echo $ITEM | tr '\\' ' ' | sed "s|:| |g" )
	done
done
