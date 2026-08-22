# MAGIC.md — myx.distro-source

Team-owned notes for the magic-* team.

## Ingesting source changes is not building the distro

- Building the distro repository prepares all output for deploy **without sources**.
- With live sources and a console open, ingest the source changes rather than building.
- `BuildDistroFromSource.fn.sh` is the build. `DistroSourcePrepare.fn.sh` is the ingest.

## The ingest gates on a change-delta

- `DistroSourcePrepare.fn.sh --sync-cached-from-source` recomputes the change-delta. When it comes out empty the command reports `no new changes` on stderr, regenerates nothing, and exits 0.
- `--ingest-distro-index-from-source` runs `--sync-cached-from-source` and then `--ingest-distro-index-from-prepared`, so it inherits that outcome: it can exit 0 having regenerated nothing.
- The cumulative list in `all-changed.index.txt` can still show a change while the recomputed delta is empty. The cumulative list is not the gate.
- Exit status does not distinguish "nothing needed doing" from "the thing you wanted did not happen". Check the artifact the ingest regenerates.

## Builders

- Only `myx.distro-source` and `myx.distro-deploy` carry pipeline builders. The system, remote, agents and `.local` packages carry none.
- Builder discovery is not limited to these packages: any project in the distro index may declare its own `builders/<stage>/<NNNN>-*.sh` and it is picked up.
- `source-publish` is matched by the builder-discovery glob as a stage-3 alternative name but has no runner behind it. Leave it in place; do not repurpose it.
