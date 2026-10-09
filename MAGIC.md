# MAGIC.md — myx.distro-source

Team-owned notes for the magic-* team.

## Goal and where things live

- The package turns a workspace source tree into the index and the outputs that deploy installs. It owns stages 1–3 of the pipeline ([Formats](docs/formats.md)).
- `sh-scripts/` holds the stage runners, the per-project list tools and the clean tools.
- `builders/<stage>/` holds this package's own pipeline builders.
- `sh-lib/source-prepare/` and `sh-lib/source-process/` hold the stage logic. `sh-lib/source-context/` holds builder and action discovery.
- `sh-lib/SourceTools.Make*.include` generate the source console, the VS Code tasks and the `.code-workspace` file. `sh-lib/console-source-bashrc.rc` is the console.

## Ingesting source changes is not building the distro

- Building the distro repository prepares all output for deploy **without sources**.
- With live sources and a console open, ingest the source changes rather than building.
- `BuildDistroFromSource.fn.sh` is the build. `DistroSourcePrepare.fn.sh` is the ingest.
- The ingest's change-delta gate, and why its exit 0 proves nothing: [Troubleshooting](docs/troubleshooting.md). The cumulative list in `all-changed.index.txt` can still show a change while the recomputed delta is empty; the cumulative list is not the gate.

## `MDSC_SOURCE`/`MDSC_CACHED`/`MDSC_OUTPUT` are stage-scoped

Each stage script reassigns them. The per-stage values are in [Formats](docs/formats.md), "Stage variables".

## Builders

- Pipeline builders are carried by `myx.distro-source`, `myx.distro-deploy` and `myx.distro-agents` (`builders/source-prepare/1201-agents-indices.sh`, `1202-harness-indices.sh`). The system, remote and `.local` packages carry none.
- Builder discovery is not limited to these packages: any project in the distro index may declare its own `builders/<stage>/<NNNN>-*.sh` and it is picked up.
- `source-publish` is a selectable build stage, discovered at `builders/source-publish/3???-*.sh`.
- `source-publish` shares the `3???` range with `image-prepare`. Discovery sorts by builder basename across stages, but a stage selection compiles to `grep '/builders/<stage>/'` and every runner selects exactly one stage, so each builder runs in its own stage, in step-number order, and builders with the same step number run in parallel. The two stages mix only in the unfiltered listing. What basename keying does cost is discovery: `ScanSourceBuilders.include` keys its result map on the basename alone across every project and stage, so two builders sharing a basename collapse to one and the loser is never listed.

## `build.number`

- `builders/source-prepare/1201-increment.sh` maintains the counter. The file contract is in [Formats](docs/formats.md), "build.number".
- The pipeline's job ends at maintaining the number. What the project does with it is the project's own business — its code may read it, embed it, or ignore it entirely. The absence of a pipeline-side consumer is not a gap to close.

## The generated `.code-workspace` lists the workspace root

- `SourceTools.Make.BuildCodeWorkspaceData.include` lists the workspace root itself as a workspace folder, alongside the namespace roots, `output` and the two generated `.vscode` folders.
- It is listed because a VS Code chat client resolves its workspace-local locations — agent skills among them — against each listed folder and never against the workspace directory. Without the root listed, everything installed at the workspace root is invisible to those clients, and no setting can name it: the settings that would are relative-only, so a value correct at one folder depth is wrong at every other. Details: `myx.distro-agents/MAGIC.md`, "VS Code skill discovery".
- The cost, double search hits: [Troubleshooting](docs/troubleshooting.md).

## `ListProjectSequence` takes a project name, and the bare script reads a different input mode

- The user-facing rules — project name, not provide-name; run it through the console; an unindexed project looks like one with no dependencies: [Troubleshooting](docs/troubleshooting.md).
- The trap is a name that is both a project name and a provide-name. It resolves, so the argument kind is never questioned, and the next call against a name that is only a provide-name then reads as a defect in that project rather than as the wrong kind of argument.
- The bare `ListProjectSequence.fn.sh` resolves `--distro-from-cached` where the console resolves `--distro-from-source`, and it under-reports without saying so.
- An empty source-mode index, or a call answering exit 0 with an empty sequence, is a workspace state to check for, never a property of the tool.
- The `image-prepare:sync-source-files` source forms (`.`, `*`, `**`) and the two conditions for severing a project: [Formats](docs/formats.md) and [Troubleshooting](docs/troubleshooting.md).

## `Augments:` and `Suggests:` gate nothing

- `docs/formats.md` states it for both: `Augments:` is a soft dependency hint that does not gate builds, `Suggests:` is informational only.
- The shell parser, `sh-lib/source-prepare/ParseSourceProjectInfToCached.fn.include`, drops both silently and emits no file for either. The awk and Java parsers index `Augments` and nothing reads that index back.
- There is no non-forking specialisation mechanism behind either key. A project that needs to vary a base is forked or sequenced, never augmented.
- `Includes:` and `Builders:` are not keys of this schema at all — neither appears in the `docs/formats.md` property list, and neither occurs in any `project.inf` in the tree. A pipeline builder is discovered by path, per "Builders" above, never declared by a key.

## `SourceConsole.include`'s prompt hook applies nothing

- The `--shell-prompt` arm reads `MDSC_INT_CD`, `cd`s to it and clears it, and cannot change the console's working directory: the `Source()` wrapper sources this include inside `( … )` and `PROMPT_COMMAND` calls that wrapper inside `$( … )`, so both statements run two subshells below the interactive shell. The arm announces the change on stderr before applying nothing, which is why it reads as working.
- Full entry: `myx.distro-.local/MAGIC.md`, "The prompt hook announces a change it cannot apply" — read there, not duplicated here.

## `CleanAllOutputs.fn.sh` clears the deploy tier along with the build outputs

- What it removes: [Troubleshooting](docs/troubleshooting.md), "A clean removed more than expected".
- **`$MMDAPP/output` is deploy staging, not a rebuildable cache.** Deploy hard-errors without it — `myx.distro-deploy/sh-scripts/DeployProjectSsh.fn.sh:364` and `:495`, `InstallPrepareFiles.fn.sh:344` and `:352`. Clearing outputs therefore clears the deploy tier, which the name does not suggest.
- It takes no confirmation and no `--force`, and its tail runs on a bare invocation. Appropriate for a tool named for exactly what it clears, and recorded as behaviour rather than as a defect: this family states no confirmation convention for destructive operations anywhere.
