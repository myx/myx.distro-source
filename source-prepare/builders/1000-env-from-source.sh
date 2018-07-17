###
### this script is included from builder
###

echo "Stage 1xxx: source to cached started" >&2

echo "BUILD_STAMP: $BUILD_STAMP" >&2
echo "MDSC_SOURCE: $MDSC_SOURCE" >&2
echo "MDSC_CACHED: $MDSC_CACHED" >&2

if [ -z "$BUILD_STAMP" ] ; then
	echo "ERROR: BUILD_STAMP is invalid or not set!" >&2 ; return 1
fi

if [ -z "$MDSC_SOURCE" ] || [ "$MDSC_SOURCE" != "$MMDAPP/source" ] ; then
	echo "ERROR: MDSC_SOURCE is invalid or not set!" >&2 ; return 1
fi

if [ ! -d "$MDSC_SOURCE" ] ; then
	echo "ERROR: MDSC_SOURCE does not exist!" >&2
	return 1
fi


if [ -z "$MDSC_CACHED" ] || [ "$MDSC_CACHED" != "$MMDAPP/cached/enhance" ] ; then
	echo "ERROR: MDSC_CACHED is invalid or not set!" >&2
	return 1
fi

mkdir -p "$MMDAPP/cached/changed"
mkdir -p "$MMDAPP/cached/enhance"
mkdir -p "$MMDAPP/cached/sources"

echo "$BUILD_STAMP" > "$MMDAPP/cached/build-time-stamp.txt"


Require DistroSourceCommand

DistroSourceCommand \
	-v \
	--import-from-source --select-all-from-source \
	--prepare-source-to-cached-index \
	--print '' \
