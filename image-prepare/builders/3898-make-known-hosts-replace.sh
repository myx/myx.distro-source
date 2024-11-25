Require RebuildKnownHosts

echo "Rebuilding 'source' KnownHosts (from scratch)..." >&2
DistroShellContext --distro-from-output
RebuildKnownHosts
