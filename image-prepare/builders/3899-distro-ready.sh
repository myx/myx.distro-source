###
### this script is included from builder
###

echo "distro-ready: publishing distro and export." >&2

echo "BUILD_STAMP: $BUILD_STAMP" >&2
echo "MDSC_SOURCE: $MDSC_SOURCE" >&2
echo "DISTRO_PATH: $DISTRO_PATH" >&2
echo "EXPORT_PATH: $EXPORT_PATH" >&2
echo "OUTPUT_PATH: $OUTPUT_PATH" >&2

Async "sync-distro" rsync -ai --delete "$MMDAPP/output/distro/" "$MMDAPP/distro"
Async "sync-export" rsync -ai --delete "$MMDAPP/output/export/" "$MMDAPP/export"

wait

echo "Stage 3xxx: 'output to distro' finished." >&2
