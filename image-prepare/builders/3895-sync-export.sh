Require ListChangedSourceProjects
Require ListProjectProvides

SyncExportsFromOutput(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "SyncExportsFromOutput: 'projectName' argument is required!" >&2 ; exit 1
	fi
	
	local SRC="$2"
	if [ -z "$SRC" ] ; then
		echo "SyncExportsFromOutput: 'SRC' argument is required!" >&2 ; exit 1
	fi
	
	local DST="$3"
	if [ -z "$DST" ] ; then
		echo "SyncExportsFromOutput: 'DST' argument is required!" >&2 ; exit 1
	fi
	
	local SOURCE_DIR="$MDSC_SOURCE/$projectName"
	local CACHED_DIR="$MDSC_CACHED/$projectName"

	local EXPORT_DST="$MMDAPP/output/export/$DST"

	if test -e "$CACHED_DIR/$SRC" ; then
		printf 'sync-export: %s %s (cached) \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2
		mkdir -p "`dirname "$EXPORT_DST"`"
		rsync -ai --delete "$CACHED_DIR/$SRC" "$EXPORT_DST"
		return 0
	fi
	
	if test -e "$SOURCE_DIR/$SRC" ; then
		printf 'sync-export: %s %s (source) \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2
		mkdir -p "`dirname "$EXPORT_DST"`"
		rsync -ai --delete "$SOURCE_DIR/$SRC" "$EXPORT_DST"
		return 0
	fi
	
	echo "ERROR: export file not found: $SRC" 
}

local projectName
for projectName in $( ListChangedSourceProjects ) ; do
	for ITEM in $( ListProjectProvides "$projectName" "deploy-export" ) ; do
		SyncExportsFromOutput "$projectName" $( echo $ITEM | tr '\\' ' ' | sed "s|:| |g" )
	done
done
