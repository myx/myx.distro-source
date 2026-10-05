# Commands

[Back to the README](../README.md)

- Run the pipeline:
	- `BuildDistroFromSource.fn.sh` — the full pipeline, through to distro and export artifacts.
	- `BuildCachedFromSource.fn.sh` — stage 1 only: source into `.local/source-cache/prepare`.
	- `BuildOutputFromCached.fn.sh` — stage 2 only: prepared cache into `.local/output-cache`.
	- `DistroSourcePrepare.fn.sh` — scan, sync and ingest source changes into the index.
	- `DistroSourceProcess.fn.sh` — ingest processed output into the index.
	- `DistroImagePrepare.fn.sh` — ingest image metadata and publish the processed index.
- Inspect one project:
	- `ListChangedSourceProjects.fn.sh` — projects marked changed for the next build.
	- `ListProjectSequence.fn.sh` — build sequence for one project.
	- `ListProjectDependants.fn.sh` — projects that depend on one project.
	- `ListProjectProvides.fn.sh` — `Provides` values for one project.
	- `ListProjectDeclares.fn.sh` — `Declares` values for one project.
	- `ListProjectKeywords.fn.sh` — `Keywords` values for one project.
- Maintain the workspace:
	- `DistroSourceTools.fn.sh` — register namespace roots, set workspace options, upgrade source tools.
	- `SyncGitSource.fn.sh` — clone or update one project from git.
	- `RebuildActions.fn.sh` — regenerate the workspace `actions/` directory.
	- `RebuildKnownHosts.fn.sh` — regenerate workspace `ssh/known_hosts` from project entries.
- Clean up:
	- `CleanAllOutputs.fn.sh` — remove every generated artifact and cache.
	- `CleanSourceToCached.fn.sh` — remove source-cache artifacts.
	- `CleanCachedToOutput.fn.sh` — remove output-stage artifacts, keep source caches.
	- `CleanOutputToDistro.fn.sh` — remove `export` and `distro`, keep earlier stages.
	- `CleanSourceFileJunk.fn.sh` — remove OS junk files and extended attributes from the source tree.
