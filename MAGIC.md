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

## `MDSC_SOURCE`/`MDSC_CACHED`/`MDSC_OUTPUT` are stage-scoped

Each stage script reassigns them to its own input and output directories. They are not fixed constants, and a value read in one stage does not describe another.

- Stage 1, `BuildCachedFromSource` — `MDSC_CACHED=.local/source-cache/prepare`.
- Stage 2, `BuildOutputFromCached` — `MDSC_CACHED=.local/output-cache/prepared`, `MDSC_OUTPUT=.local/output-cache`.
- Outside an active stage, which is where ad-hoc commands run, `MDSC_CACHED` defaults to `.local/system-index` — the published steady-state index, and what most day-to-day commands see.

The stage table, folder meanings and variable definitions are in `README.md`.

## Builders

- Only `myx.distro-source` and `myx.distro-deploy` carry pipeline builders. The system, remote, agents and `.local` packages carry none.
- Builder discovery is not limited to these packages: any project in the distro index may declare its own `builders/<stage>/<NNNN>-*.sh` and it is picked up.
- `source-publish` is a selectable build stage, discovered at `builders/source-publish/3???-*.sh`.
- `source-publish` shares the `3???` range with `image-prepare`. Discovery sorts by builder basename across stages, so builders of the two run interleaved in numeric order, not as separate blocks.

## `build.number`

- `builders/source-prepare/1201-increment.sh` maintains `source/<project>/build.number` for changed projects whose `Provides` carry `source-prepare:increment` and ` build.number`.
- The file holds a decimal integer and a trailing newline, nothing else. An absent file initialises to `1`.
- Any other content — empty, non-digit, padded or multi-line — is an error: the existing file is left untouched and the builder exits non-zero.
- A new value goes to a temp file beside the target and is `mv`-ed into place, so a failed write never truncates the existing value.
- The counter lives in `source/`, not in the cache, and needs no commit or push: the source tree is picked up by ingest, not by a git round-trip.
- The pipeline's job ends at maintaining the number. The file sits in the project's own source, and what the project does with it is the project's own business — its code may read it, embed it, or ignore it entirely. The absence of a pipeline-side consumer is not a gap to close.
