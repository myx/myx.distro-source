#!/bin/bash
# ^^^ for syntax checking in the editor only

# Copy one named built artefact into the export tree, so an image-prepare key can
# serve it. The sibling 3895-sync-export.sh copies a path inside a project's own
# source or cached tree. A build writes outside both, into the output tree, so it
# needs a builder of its own and a key of its own.
#
# The declaration this reads is `deploy-export-built:` on the building project, in
# the same shape as `deploy-export:`:
#
#	deploy-export-built:camunda7-dist/7.24.0-fork.5:camunda7/7.24.0-fork.5
#
# The token after the project is a path under $MDSC_OUTPUT/<project>, so a build's
# release directory reaches the share without being copied into a source tree.
#
# A building project publishes one tag per declaration, so the tag is written into
# the line. Nothing rewrites the line when the fork moves to a new tag, and a tag
# this line does not name is not published.
#
# A file whose bytes have not changed is left alone, so a second build of an
# unchanged tree publishes nothing and rsync reports no transfer. `--checksum` is
# what makes that true: without it rsync transfers a file whose bytes are the same
# and whose mtime moved, which is every file of a Maven rebuild.

# The account says which happened: a transfer line is reported as what it is, and a
# run that copied nothing says so, so silence never has to be read as success.
SyncBuiltExportsFromOutput(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "⛔ ERROR: SyncBuiltExportsFromOutput: 'projectName' argument is required!" >&2 ; return 1
	fi

	local SRC="$2"
	if [ -z "$SRC" ] ; then
		echo "⛔ ERROR: SyncBuiltExportsFromOutput: 'SRC' argument is required!" >&2 ; return 1
	fi

	local DST="$3"
	if [ -z "$DST" ] ; then
		echo "⛔ ERROR: SyncBuiltExportsFromOutput: 'DST' argument is required!" >&2 ; return 1
	fi

	local BUILT_DIR="$MDSC_OUTPUT/$projectName"
	local EXPORT_DST="$MMDAPP/.local/output-cache/export/$DST"

	if [ ! -e "$BUILT_DIR/$SRC" ] ; then
		echo "⛔ ERROR: built export not found: $BUILT_DIR/$SRC"
		return 1
	fi

	printf 'sync-built-export: %s %s \n \t \t <= %s\n' "$projectName" "$SRC" "$DST" >&2

	local rsyncOutput

	if [ -d "$BUILT_DIR/$SRC" ] ; then
		mkdir -p "$EXPORT_DST"
		rsyncOutput="$( rsync -ai --checksum --delete "$BUILT_DIR/$SRC"/ "$EXPORT_DST"/ 2>&1 )"
	else
		mkdir -p "${EXPORT_DST%/*}"
		rsyncOutput="$( rsync -ai --checksum "$BUILT_DIR/$SRC" "$EXPORT_DST" 2>&1 )"
	fi

	# A `>f` line is a file this run copied. Everything else rsync said is passed on as
	# it came, so a refusal or a warning is never swallowed.
	printf '%s\n' "$rsyncOutput" | grep -v -E '^\.f' | grep -v '^$' >&2 || :

	if printf '%s\n' "$rsyncOutput" | grep -q -E '^>f' ; then
		printf 'sync-built-export: %s %s published\n' "$projectName" "$DST" >&2
	else
		printf 'sync-built-export: %s %s already current, nothing published\n' "$projectName" "$DST" >&2
	fi
	return 0
}

Require ListDistroProvides
Distro ListDistroProvides --select-changed --filter-and-cut "deploy-export-built" \
| sed "s|:| |g" \
| while read -r projectName sourceName targetName ; do
	SyncBuiltExportsFromOutput "$projectName" "$sourceName" "$targetName"
done
