
echo "Rebuilding 'source' actions (merge with current actions)..." >&2

DistroSystemContext --distro-from-source
Distro RebuildActions --no-delete
