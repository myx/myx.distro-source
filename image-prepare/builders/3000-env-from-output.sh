###
### this script is included from builder
###

echo "Stage 3xxx: output to distro started" >&2

echo "BUILD_STAMP: $BUILD_STAMP" >&2
echo "MDSC_SOURCE: $MDSC_SOURCE" >&2
echo "MDSC_CACHED: $MDSC_CACHED" >&2
echo "OUTPUT_PATH: $OUTPUT_PATH" >&2
echo "DISTRO_PATH: $DISTRO_PATH" >&2
echo "EXPORT_PATH: $EXPORT_PATH" >&2

if [ -z "$BUILD_STAMP" ] ; then
	echo "ERROR: BUILD_STAMP is invalid or not set!" >&2 ; return 1
fi

if [ -z "$MDSC_SOURCE" ] || [ "$MDSC_SOURCE" != "$MMDAPP/output/distro" ] ; then
	echo "ERROR: MDSC_SOURCE is invalid or not set!" >&2 ; return 1
fi


if [ ! -d "$MDSC_SOURCE" ] ; then
	echo "ERROR: MDSC_SOURCE does not exist!" >&2 ; return 1
fi


if [ -z "$MDSC_CACHED" ] || [ "$MDSC_CACHED" != "$MMDAPP/output/cached" ] ; then
	echo "ERROR: MDSC_CACHED is invalid or not set!" >&2 ; return 1
fi


if [ -z "$OUTPUT_PATH" ] || [ "$OUTPUT_PATH" != "$MMDAPP/output/distro" ] ; then
	echo "ERROR: OUTPUT_PATH is invalid or not set!" >&2 ; return 1
fi

if [ ! -d "$MMDAPP/output" ] ; then
	echo "ERROR: MMDAPP/output does not exist!" >&2 ; return 1
fi


if [ -z "$DISTRO_PATH" ] || [ "$DISTRO_PATH" != "$MMDAPP/output/distro" ] ; then
	echo "ERROR: DISTRO_PATH is invalid or not set!" >&2 ; return 1
fi
if [ -z "$EXPORT_PATH" ] || [ "$EXPORT_PATH" != "$MMDAPP/output/export" ] ; then
	echo "ERROR: EXPORT_PATH is invalid or not set!" >&2 ; return 1
fi


mkdir -p "$DISTRO_PATH"
mkdir -p "$EXPORT_PATH"

echo "$BUILD_STAMP" > "$DISTRO_PATH/build-time-stamp.txt"
echo "$BUILD_STAMP" > "$EXPORT_PATH/build-time-stamp.txt"
