#!/bin/sh

[ full != "$MDSC_DETAIL" ] || set -x

Distro ListDistroProvides --select-changed --filter-and-cut "source-prepare:increment" \
| { grep -e " build.number$" || [ $? -eq 1 ] ; } \
| cut -d" " -f1 \
| while read -r projectName ; do
	PROJECT_DIR="$MMDAPP/source/${projectName#$MMDAPP/source/}"
	GIT_CLEAN=no
	GIT_ROOT="$( git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null )"
	if [ -n "$GIT_ROOT" ] ; then
		GIT_DIRTY="$( git -C "$GIT_ROOT" status --porcelain -- "$PROJECT_DIR" 2>/dev/null )"
		[ -n "$GIT_DIRTY" ] || GIT_CLEAN=yes
	fi
	if [ yes = "$GIT_CLEAN" ] ; then
		echo "build.number: $projectName: SKIP (no uncommitted changes)" >&2
		continue
	fi

	CHECK_FILE="$PROJECT_DIR/build.number"
	if [ -f "$CHECK_FILE" ] ; then
		CHECK_VALUE="$( cat "$CHECK_FILE" )"
		case "$CHECK_VALUE" in
			"" | *[!0-9]* )
				echo "⛔ ERROR: build.number: $projectName: not an integer: '$CHECK_VALUE'" >&2
				exit 1
			;;
		esac
		while : ; do case "$CHECK_VALUE" in
			0?* ) CHECK_VALUE="${CHECK_VALUE#0}" ;;
			* ) break ;;
		esac done
		BUILD_VALUE="$(( CHECK_VALUE + 1 ))"
		echo "build.number: $projectName: INCREMENT! -> $BUILD_VALUE" >&2
	else
		BUILD_VALUE=1
		echo "build.number: $projectName: INIT! -> $BUILD_VALUE" >&2
	fi

	WRITE_FILE="$CHECK_FILE.$$.tmp"
	printf '%s\n' "$BUILD_VALUE" > "$WRITE_FILE" && mv -f "$WRITE_FILE" "$CHECK_FILE" || {
		rm -f "$WRITE_FILE"
		echo "⛔ ERROR: build.number: $projectName: could not write: $CHECK_FILE" >&2
		exit 1
	}
done
