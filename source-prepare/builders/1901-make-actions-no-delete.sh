Require RebuildActions

echo "Rebuilding 'source' actions (merge with current actions)..." >&2
DistroSystemContext --distro-from-source
RebuildActions --no-delete
