echo "Rebuilding 'source' actions (merge with current actions)..." >&2
DistroSystemContext --distro-from-cached

Require RebuildActions
RebuildActions --no-delete
