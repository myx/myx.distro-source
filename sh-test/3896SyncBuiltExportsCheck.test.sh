#!/usr/bin/env bash
## Offline check of the built-export builder, run rather than read.
## Nothing is built and nothing outside the rig is touched: MDSC_OUTPUT and MMDAPP both
## point at a scratch tree made here, and the builder's dispatch tail is cut off so no
## Distro call ever runs.
## What the rows establish, one per statement of the declaration it serves:
##   - one named artefact reaches the export tree, and its bytes are the built bytes;
##   - a second run over unchanged bytes moves nothing, and says so;
##   - a changed byte is transferred and reported as published;
##   - two tags publish side by side, and neither disturbs the other;
##   - a file artefact lands under the name it was given;
##   - an absent artefact is reported on stderr, and the run goes on to its next row;
##   - a missing argument stops.
## The rig refuses to report unless the builder under test is the file it names, so a run
## that never loaded its subject cannot print a pass line.
set -u

# The project name the dispatch tail passes is the whole-index name, which the producer
# uses as its own output folder. A rig that shortens it tests a tree no build writes.
rigProject="mdv/mdci-packages-mdv/build.feature-camunda7"

rigHere="$( cd "$( dirname "$0" )" && pwd -P )" || exit 1
rigBuilder="${RIG_BUILDER:-${rigHere%/sh-test}/builders/image-prepare/3896-sync-built-exports.sh}"
rigWork="$( mktemp -d "${TMPDIR:-/tmp}/sync-built-exports-check.XXXXXX" )" || exit 1
trap 'rm -rf -- "$rigWork"' EXIT

rigRefuse(){ echo "⛔ ERROR: $1 -- refusing to report a result" >&2 ; exit 1 ; }
[ -f "$rigBuilder" ] || rigRefuse "no builder at $rigBuilder"
grep -q 'SyncBuiltExportsFromOutput' "$rigBuilder" || rigRefuse "builder defines no SyncBuiltExportsFromOutput"
command -v rsync > /dev/null 2>&1 || rigRefuse "no rsync on PATH, so nothing can be copied"

# The builder reaches Distro for its targets; the rig sources the file with the dispatch
# tail cut off, so calling the function never gets there.
sed -e '/^Require ListDistroProvides/,$d' "$rigBuilder" > "$rigWork/builder.sh"
bash -n "$rigWork/builder.sh" || rigRefuse "the builder's function body does not parse"

rigPass=0
rigFail=0
rigCheck(){
	if [ "$2" = "$3" ] ; then
		rigPass=$(( rigPass + 1 ))
		printf '  PASS  %s\n' "$1"
	else
		rigFail=$(( rigFail + 1 ))
		printf '  FAIL  %s\n        expected: %s\n        actual:   %s\n' "$1" "$3" "$2"
	fi
}

rigBuilt="$rigWork/built"
rigApp="$rigWork/app"
rigExport="$rigApp/.local/output-cache/export"
export MDSC_OUTPUT="$rigBuilt"
export MMDAPP="$rigApp"

# A fresh built tree and export tree, so no row reads what the row before it left.
rigFresh(){
	rm -rf "$rigBuilt" "$rigApp"
	mkdir -p "$rigBuilt/$rigProject" "$rigExport"
}

# shellcheck disable=SC1091
. "$rigWork/builder.sh"

printf '\n== one named artefact reaches the export tree ==\n'
rigFresh
mkdir -p "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5"
printf 'archive-payload\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz"
printf 'aa\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda7-7.24.0-fork.5.pkg"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.5" "camunda7/7.24.0-fork.5" 2> "$rigWork/row1.err"
rigRc=$?
rigCheck "returns 0 for an artefact it copied" "$rigRc" "0"
rigCheck "says it published" "$( grep -c 'published$' "$rigWork/row1.err" )" "1"
rigCheck "the archive's bytes are the built bytes" \
	"$( shasum -a 256 < "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" 2>/dev/null )" \
	"$( shasum -a 256 < "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz" )"
rigCheck "both files of the release landed" \
	"$( ls -1 "$rigExport/camunda7/7.24.0-fork.5" 2>/dev/null | wc -l | tr -d ' ' )" "2"

printf '\n== a second run over unchanged bytes moves nothing ==\n'
# The subject is --checksum. A Maven rebuild rewrites every file with the same bytes and a
# newer mtime, so a moved mtime alone must not be read as a change.
sleep 1
touch "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz"
rigInodeBefore="$( stat -f '%i' "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" 2>/dev/null )"
[ -n "$rigInodeBefore" ] || rigRefuse "the first row left no destination file to compare against"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.5" "camunda7/7.24.0-fork.5" 2> "$rigWork/row2.err"
rigCheck "says it published nothing" "$( grep -c 'already current, nothing published' "$rigWork/row2.err" )" "1"
rigCheck "the destination inode did not move" \
	"$( stat -f '%i' "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" )" "$rigInodeBefore"

printf '\n== one changed byte is transferred and reported ==\n'
printf 'archive-payload\nx\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.5" "camunda7/7.24.0-fork.5" 2> "$rigWork/row3.err"
rigCheck "says it published" "$( grep -c 'published$' "$rigWork/row3.err" )" "1"
rigCheck "the changed byte reached the export tree" \
	"$( shasum -a 256 < "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" 2>/dev/null )" \
	"$( shasum -a 256 < "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz" )"

printf '\n== two tags publish side by side ==\n'
mkdir -p "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.6"
printf 'next-tag\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.6/camunda-bpm-run.tar.gz"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.6" "camunda7/7.24.0-fork.6" 2> "$rigWork/row4.err"
rigCheck "the second tag landed" \
	"$( [ -f "$rigExport/camunda7/7.24.0-fork.6/camunda-bpm-run.tar.gz" ] && echo yes )" "yes"
rigCheck "the first tag is still there" \
	"$( [ -f "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" ] && echo yes )" "yes"

printf '\n== a file artefact lands under the name it was given ==\n'
rigFresh
mkdir -p "$rigBuilt/$rigProject/camunda7-dist"
printf 'one-file\n' > "$rigBuilt/$rigProject/camunda7-dist/camunda7-7.24.0-fork.5.pkg"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/camunda7-7.24.0-fork.5.pkg" "camunda7/7.24.0-fork.5/camunda7-7.24.0-fork.5.pkg" 2> "$rigWork/row5.err"
rigCheck "the file landed with its own name" \
	"$( [ -f "$rigExport/camunda7/7.24.0-fork.5/camunda7-7.24.0-fork.5.pkg" ] && echo yes )" "yes"

printf '\n== an absent artefact is reported on stderr, and does not stop the run ==\n'
rigFresh
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/absent-tag" "camunda7/absent-tag" 2> "$rigWork/row6.err"
rigCheck "names the path it looked for, on stderr" "$( grep -c 'built export not found' "$rigWork/row6.err" )" "1"
# A row before a missing one lands, and the missing one does not end the stage: a second
# artefact in the same run is still published.
mkdir -p "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5"
printf 'later-row\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/absent-tag" "camunda7/absent-tag" 2> /dev/null
rigCheck "returns 0, so the next row still runs" "$?" "0"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.5" "camunda7/7.24.0-fork.5" 2> /dev/null
rigCheck "the next row published" \
	"$( [ -f "$rigExport/camunda7/7.24.0-fork.5/camunda-bpm-run.tar.gz" ] && echo yes )" "yes"

printf '\n== a copy that cannot be written does not report as nothing to publish ==\n'
rigFresh
mkdir -p "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5"
printf 'payload\n' > "$rigBuilt/$rigProject/camunda7-dist/7.24.0-fork.5/camunda-bpm-run.tar.gz"
# An existing regular file where the builder needs a directory. rsync then copies nothing.
mkdir -p "$rigExport/camunda7"
: > "$rigExport/camunda7/blocked"
SyncBuiltExportsFromOutput "$rigProject" "camunda7-dist/7.24.0-fork.5" "camunda7/blocked" 2> "$rigWork/row7.err"
rigRc=$?
rigCheck "returns non-zero when the copy failed" "$rigRc" "1"
rigCheck "does not claim there was nothing to publish" \
	"$( grep -c 'already current, nothing published' "$rigWork/row7.err" )" "0"
rigCheck "names the failure" "$( grep -c 'not copied, rsync answered' "$rigWork/row7.err" )" "1"

printf '\n== a missing argument stops ==\n'
SyncBuiltExportsFromOutput "" "a" "b" 2> /dev/null
rigCheck "an empty project name returns non-zero" "$?" "1"
SyncBuiltExportsFromOutput "p" "" "b" 2> /dev/null
rigCheck "an empty source returns non-zero" "$?" "1"
SyncBuiltExportsFromOutput "p" "a" "" 2> /dev/null
rigCheck "an empty destination returns non-zero" "$?" "1"

printf '\n== the live declaration line parses into three fields ==\n'
# Put through the builder's own sed, as its dispatch tail does it.
rigDecl="mdv/mdci-packages-mdv/build.feature-camunda7 camunda7-dist/7.24.0-fork.5:camunda7/7.24.0-fork.5"
rigCheck "the line yields three fields" \
	"$( printf '%s\n' "$rigDecl" | sed 's|:| |g' | awk '{ print NF }' )" "3"
rigCheck "the source field is the tag path" \
	"$( printf '%s\n' "$rigDecl" | sed 's|:| |g' | awk '{ print $2 }' )" "camunda7-dist/7.24.0-fork.5"

printf '\nRESULT: %s passed, %s failed\n' "$rigPass" "$rigFail"
[ "$rigFail" -eq 0 ] || exit 1
