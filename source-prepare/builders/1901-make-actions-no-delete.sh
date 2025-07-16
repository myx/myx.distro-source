
echo "Rebuilding 'source' actions (merge with current actions)..." >&2

[ "full" != "$MDSC_DETAIL" ] || set -x

DistroSystemContext --distro-from-source
Distro RebuildActions --no-delete
