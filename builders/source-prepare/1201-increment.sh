#!/bin/sh

[ full != "$MDSC_DETAIL" ] || set -x

Distro ListDistroProvides --select-changed --filter-and-cut "source-prepare:increment" \
| { grep -e " build.number$" || [ $? -eq 1 ] ; } \
| cut -d" " -f1 \
| while read -r projectName ; do
	CHECK_FILE="$MMDAPP/source/${projectName#$MMDAPP/source/}/build.number"
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
		echo "build.number: $projectName: INCREMENT!" >&2
	else
		BUILD_VALUE=1
		echo "build.number: $projectName: INIT!" >&2
	fi

	WRITE_FILE="$CHECK_FILE.$$.tmp"
	printf '%s\n' "$BUILD_VALUE" > "$WRITE_FILE" && mv -f "$WRITE_FILE" "$CHECK_FILE" || {
		rm -f "$WRITE_FILE"
		echo "⛔ ERROR: build.number: $projectName: could not write: $CHECK_FILE" >&2
		exit 1
	}
done