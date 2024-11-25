Require RebuildKnownHosts

echo "Rebuilding 'source' KnownHosts (merge with current actions)..." >&2
DistroShellContext --distro-from-cached
RebuildKnownHosts --no-delete
