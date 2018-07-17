Require ListChangedSourceProjects
Require ListProjectProvides
Require ListProjectSequence

MergeScripts(){
	local projectName="${1#$MMDAPP/source/}"
	if [ -z "$projectName" ] ; then
		echo "MergeScripts: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local SRC_NAME="$2"
	if [ -z "$SRC_NAME" ] ; then
		echo "MergeScripts: 'SRC_NAME' argument is required!" >&2 ; return 1
	fi
	
	local DST_NAME="$3"
	if [ -z "$DST_NAME" ] ; then
		echo "MergeScripts: 'DST_NAME' argument is required!" >&2 ; return 1
	fi
	
	local OUTPUT_DST="$MDSC_OUTPUT/$projectName/$DST_NAME"
	echo "merge: $SRC_NAME to $DST_NAME" >&2

	echo "# merged by myx.distro at `date` @ `hostname`" > "$OUTPUT_DST"
	
	for SEQUENCE in $( ListProjectSequence "$projectName" ) ; do
		echo "sequence: $SEQUENCE" >&2
		local SRC_FILE="$MDSC_CACHED/$SEQUENCE/$SRC_NAME"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$SRC_NAME (cached)" >&2
			echo "# merged from $SEQUENCE/$SRC_NAME (cached)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		local SRC_FILE="$MDSC_OUTPUT/$SEQUENCE/$SRC_NAME"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$SRC_NAME (output)" >&2
			echo "# merged from $SEQUENCE/$SRC_NAME (output)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		local SRC_FILE="$MDSC_SOURCE/$SEQUENCE/$SRC_NAME"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$SRC_NAME (source)" >&2
			echo "# merged from $SEQUENCE/$SRC_NAME (source)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		
		echo "merging: $SEQUENCE/$SRC_NAME skipped (no source file)." >&2
	done
	
	echo "# end of merge " >> "$OUTPUT_DST"
}

for projectName in $( ListChangedSourceProjects ) ; do
	for ITEM in $( ListProjectProvides "$projectName" "source-process-merge-scripts" ) ; do
		Async -2 MergeScripts "$projectName" ` echo $ITEM | tr '\\' ' ' | sed "s|:| |g" `
		wait
	done
done
