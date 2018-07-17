###
### this script is included from builder
###

echo "Stage 2xxx: cached to output started" >&2

echo "BUILD_STAMP: $BUILD_STAMP" >&2
echo "MDSC_SOURCE: $MDSC_SOURCE" >&2
echo "MDSC_CACHED: $MDSC_CACHED" >&2
echo "OUTPUT_PATH: $OUTPUT_PATH" >&2

if [ -z "$BUILD_STAMP" ] ; then
	echo "ERROR: BUILD_STAMP is invalid or not set!" >&2
	return 1
fi

if [ -z "$MDSC_SOURCE" ] || [ "$MDSC_SOURCE" != "$MMDAPP/cached/sources" ] ; then
	echo "ERROR: MDSC_SOURCE is invalid or not set!" >&2
	return 1
fi

if [ ! -d "$MDSC_SOURCE" ] ; then
	echo "ERROR: MDSC_SOURCE does not exist!" >&2
	return 1
fi


if [ -z "$MDSC_CACHED" ] || [ "$MDSC_CACHED" != "$MMDAPP/cached/enhance" ] ; then
	echo "ERROR: MDSC_CACHED is invalid or not set!" >&2
	return 1
fi



if [ -z "$OUTPUT_PATH" ] || [ "$OUTPUT_PATH" != "$MMDAPP/output" ] ; then
	echo "ERROR: OUTPUT_PATH is invalid or not set!" >&2
	return 1
fi

mkdir -p "$OUTPUT_PATH"
mkdir -p "$MDSC_CACHED"

mkdir -p "$OUTPUT_PATH/distro"
mkdir -p "$OUTPUT_PATH/export"

echo "$BUILD_STAMP" > "$MMDAPP/output/build-time-stamp.txt"