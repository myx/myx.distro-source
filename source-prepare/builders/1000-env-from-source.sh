###
### this script is included from builder
###

echo "Stage 1xxx: source to cached started" >&2

echo "BUILD_STAMP: $BUILD_STAMP" >&2
echo "MDSC_SOURCE: $MDSC_SOURCE" >&2
echo "MDSC_CACHED: $MDSC_CACHED" >&2
echo "MDSC_OUTPUT: $MDSC_OUTPUT" >&2

if [ -z "$BUILD_STAMP" ] ; then
	echo "⛔ ERROR: BUILD_STAMP is invalid or not set!" >&2
	return 1
fi

if [ -z "$MDSC_SOURCE" ] || [ "$MDSC_SOURCE" != "$MMDAPP/source" ] ; then
	echo "⛔ ERROR: MDSC_SOURCE is invalid or not set!" >&2
	return 1
fi

if [ ! -d "$MDSC_SOURCE" ] ; then
	echo "⛔ ERROR: MDSC_SOURCE does not exist!" >&2
	return 1
fi


if [ -z "$MDSC_CACHED" ] || [ "$MDSC_CACHED" != "$MMDAPP/.local/source-cache/enhance" ] ; then
	echo "⛔ ERROR: MDSC_CACHED is invalid or not set: $MDSC_CACHED" >&2
	return 1
fi

mkdir -p "$MMDAPP/.local/source-cache/changed"
mkdir -p "$MMDAPP/.local/source-cache/enhance"
mkdir -p "$MMDAPP/.local/source-cache/sources"

echo "$BUILD_STAMP" > "$MMDAPP/.local/source-cache/build-time-stamp.txt"

Distro DistroSourcePrepare --ingest-distro-index-from-source
