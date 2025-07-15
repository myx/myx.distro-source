
echo "Rebuilding 'source' actions (merge with current actions)..." >&2

DistroSystemContext --distro-from-cached
Distro RebuildActions --no-delete
