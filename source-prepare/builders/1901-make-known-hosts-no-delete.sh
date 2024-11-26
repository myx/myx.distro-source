Require RebuildKnownHosts

echo "Rebuilding 'source' KnownHosts (merge with current actions)..." >&2
DistroShellContext --distro-from-source
RebuildKnownHosts --no-delete
