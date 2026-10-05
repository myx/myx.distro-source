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


## Stage and index commands

Every stage runner takes `--help` and `--help-syntax`. The runners that run builders also take `--continue`, which keeps going after a builder fails.

- `DistroSourcePrepare.fn.sh <option>`
	- `--scan-source-projects` — list the projects found under the source roots.
	- `--scan-source-namespaces` — list the namespaces found under the source roots.
	- `--scan-source-changes` — print the detected source changes.
	- `--sync-cached-from-source` — sync source changes into the `source-cache/prepare` state.
	- `--ingest-distro-index-from-prepared` — publish the prepared index data to the system index.
	- `--ingest-distro-index-from-source` — run the sync, then the ingest.
	- `--rebuild-cached-index` — rebuild the cached distro index and its derived files.
	- `--build-project-metadata` — build the per-project declares, keywords, provides, requires and sequence data.
- `DistroSourceProcess.fn.sh <option>`
	- `--ingest-distro-output-from-cached` — sync the prepared output into the output-cache state.
	- `--ingest-distro-index-from-processed` — publish the processed index data to the system index.
	- `--ingest-distro-index-from-cached` — run the output ingest, then the index ingest.
	- `--rebuild-output-index` — rebuild the output index and its derived files.
	- `--clone-prepared-metadata` — clone the prepared metadata into the output-cache state.
- `DistroImagePrepare.fn.sh <option>`
	- `--ingest-distro-image-from-output` — ingest the image metadata from the output state.
	- `--ingest-distro-index-from-processed` — publish the processed index data to the system index.
	- `--rebuild-cached-index` — rebuild the cached distro index and its derived files.
- `BuildDistroFromSource.fn.sh [--only] [--continue]` — `--only`, or `--build-distro-from-output`, runs only the final output-to-distro stage.
- `RebuildActions.fn.sh [--no-delete]` — `--no-delete` keeps generated action files that no longer appear in the source index.
- `SyncGitSource.fn.sh <project-name> <git-repository-spec>` — takes exactly these two arguments. It rejects a third one, such as a branch.
- `ListProjectSequence.fn.sh [--no-cache] <project-name> [--print-project] [--print-provides|--print-declares|--print-keywords]` — takes a project name. [Troubleshooting](troubleshooting.md) explains how to run it.

## What each clean command removes

- `CleanSourceToCached.fn.sh` — the source-cache artefacts, so ingest and prepare start fresh.
- `CleanCachedToOutput.fn.sh` — `.local/output-cache` and `output`. The source-side caches stay.
- `CleanOutputToDistro.fn.sh` — `export` and `distro`. Earlier stages stay.
- `CleanAllOutputs.fn.sh` — every generated artefact and cache, the index included. [Troubleshooting](troubleshooting.md) lists what goes.


## Manuals

Each tool has a manual with its full syntax, options and examples.

- [BuildCachedFromSource](../sh-lib/help/Help.BuildCachedFromSource.help.md)
- [BuildDistroFromSource](../sh-lib/help/Help.BuildDistroFromSource.help.md)
- [BuildOutputFromCached](../sh-lib/help/Help.BuildOutputFromCached.help.md)
- [CleanAllOutputs](../sh-lib/help/Help.CleanAllOutputs.help.md)
- [CleanCachedToOutput](../sh-lib/help/Help.CleanCachedToOutput.help.md)
- [CleanOutputToDistro](../sh-lib/help/Help.CleanOutputToDistro.help.md)
- [CleanSourceFileJunk](../sh-lib/help/Help.CleanSourceFileJunk.help.md)
- [CleanSourceToCached](../sh-lib/help/Help.CleanSourceToCached.help.md)
- [DistroImagePrepare](../sh-lib/help/Help.DistroImagePrepare.help.md)
- [DistroSourcePrepare](../sh-lib/help/Help.DistroSourcePrepare.help.md)
- [DistroSourceProcess](../sh-lib/help/Help.DistroSourceProcess.help.md)
- [DistroSourceTools](../sh-lib/help/Help.DistroSourceTools.help.md)
- [Help](../sh-lib/help/Help.Help.help.md)
- [ListChangedSourceProjects](../sh-lib/help/Help.ListChangedSourceProjects.help.md)
- [ListProjectDeclares](../sh-lib/help/Help.ListProjectDeclares.help.md)
- [ListProjectDependants](../sh-lib/help/Help.ListProjectDependants.help.md)
- [ListProjectKeywords](../sh-lib/help/Help.ListProjectKeywords.help.md)
- [ListProjectProvides](../sh-lib/help/Help.ListProjectProvides.help.md)
- [ListProjectSequence](../sh-lib/help/Help.ListProjectSequence.help.md)
- [RebuildActions](../sh-lib/help/Help.RebuildActions.help.md)
- [RebuildKnownHosts](../sh-lib/help/Help.RebuildKnownHosts.help.md)
- [SyncGitSource](../sh-lib/help/Help.SyncGitSource.help.md)
