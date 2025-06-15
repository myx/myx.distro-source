Require RebuildKnownHosts

echo "Rebuilding 'source' KnownHosts (merge with current actions)..." >&2
DistroSystemContext --distro-from-source
RebuildKnownHosts --no-delete
