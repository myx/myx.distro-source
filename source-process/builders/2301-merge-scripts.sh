#!/bin/sh

# 	source-process-merge-scripts:sh-scripts/extra/install-freebsd.sh:install-freebsd-instance.sh \

Require ListProjectSequence
Require ListDistroProvides

MergeScripts(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: MergeScripts: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local sourceName="$2"
	if [ -z "$sourceName" ] ; then
		echo "⛔ ERROR: MergeScripts: 'sourceName' argument is required!" >&2 ; return 1
	fi
	
	local targetName="$3"
	if [ -z "$targetName" ] ; then
		echo "⛔ ERROR: MergeScripts: 'targetName' argument is required!" >&2 ; return 1
	fi
	
	local OUTPUT_DST="$MDSC_OUTPUT/distro/$projectName/$targetName"
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
		local SRC_FILE="$MDSC_OUTPUT/distro/$SEQUENCE/$sourceName"
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

type Prefix >/dev/null 2>&1 || . "$( myx.common which lib/prefix )"
type Parallel >/dev/null 2>&1 || . "$( myx.common which lib/parallel )"

ListDistroProvides --select-changed --filter-and-cut "source-process-merge-scripts" \
| sed "s|:| |g" \
| Parallel Prefix -2 MergeScripts # "$projectName" "$sourceName" "$targetName"
