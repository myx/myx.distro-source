Require ListProjectSequence
Require ListDistroProvides

# 	source-process-merge-scripts:sh-scripts/extra/install-freebsd.sh:install-freebsd-instance.sh \


MergeScripts(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "MergeScripts: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local sourceName="$2"
	if [ -z "$sourceName" ] ; then
		echo "MergeScripts: 'sourceName' argument is required!" >&2 ; return 1
	fi
	
	local targetName="$3"
	if [ -z "$targetName" ] ; then
		echo "MergeScripts: 'targetName' argument is required!" >&2 ; return 1
	fi
	
	local OUTPUT_DST="$MDSC_OUTPUT/$projectName/$targetName"
	echo "merge: $sourceName to $targetName" >&2

	echo "# merged by myx.distro at `date` @ `hostname`" > "$OUTPUT_DST"
	
	for SEQUENCE in $( ListProjectSequence "$projectName" ) ; do
		echo "sequence: $SEQUENCE" >&2
		local SRC_FILE="$MDSC_CACHED/$SEQUENCE/$sourceName"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$sourceName (cached)" >&2
			echo "# merged from $SEQUENCE/$sourceName (cached)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		local SRC_FILE="$MDSC_OUTPUT/$SEQUENCE/$sourceName"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$sourceName (output)" >&2
			echo "# merged from $SEQUENCE/$sourceName (output)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		local SRC_FILE="$MDSC_SOURCE/$SEQUENCE/$sourceName"
		if [ -f "$SRC_FILE" ] ; then
			echo "merging: $SEQUENCE/$sourceName (source)" >&2
			echo "# merged from $SEQUENCE/$sourceName (source)" >> "$OUTPUT_DST"
			cat "$SRC_FILE" >> "$OUTPUT_DST"
			continue
		fi
		
		echo "merging: $SEQUENCE/$sourceName skipped (no source file)." >&2
	done
	
	echo "# end of merge " >> "$OUTPUT_DST"
}


ListDistroProvides --select-changed --filter-and-cut "source-process-merge-scripts" | sed "s|:| |g" | while read -r projectName sourceName targetName ; do
	Async -2 MergeScripts "$projectName" "$sourceName" "$targetName"
	wait
done
