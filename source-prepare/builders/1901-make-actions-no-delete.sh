Require RebuildActions

echo "Rebuilding 'source' actions (merge with current actions)..." >&2
DistroShellContext --distro-from-source
RebuildActions --no-delete
