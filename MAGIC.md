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
- `source-publish` shares the `3???` range with `image-prepare`. Discovery sorts by builder basename across stages, but a stage selection compiles to `grep '/builders/<stage>/'` and every runner selects exactly one stage, so the two never interleave at execution — only in the unfiltered listing. What basename keying does cost is discovery: `ScanSourceBuilders.include` keys its result map on the basename alone across every project and stage, so two builders sharing a basename collapse to one and the loser is never listed.

## `build.number`

- `builders/source-prepare/1201-increment.sh` maintains `source/<project>/build.number` for changed projects whose `Provides` carry `source-prepare:increment` and ` build.number`.
- The file holds a decimal integer and a trailing newline, nothing else. An absent file initialises to `1`.
- Any other content — empty, non-digit, padded or multi-line — is an error: the existing file is left untouched and the builder exits non-zero.
- A new value goes to a temp file beside the target and is `mv`-ed into place, so a failed write never truncates the existing value.
- The counter lives in `source/`, not in the cache, and needs no commit or push: the source tree is picked up by ingest, not by a git round-trip.
- The pipeline's job ends at maintaining the number. The file sits in the project's own source, and what the project does with it is the project's own business — its code may read it, embed it, or ignore it entirely. The absence of a pipeline-side consumer is not a gap to close.

## The generated `.code-workspace` lists the workspace root

- `SourceTools.Make.BuildCodeWorkspaceData.include` lists the workspace root itself as a workspace folder, alongside the namespace roots, `output` and the two generated `.vscode` folders.
- It is listed because a VS Code chat client resolves its workspace-local locations — agent skills among them — against each listed folder and never against the workspace directory. Without the root listed, everything installed at the workspace root is invisible to those clients, and no setting can name it: the settings that would are relative-only, so a value correct at one folder depth is wrong at every other. Details: `myx.distro-agents/MAGIC.md`, "VS Code skill discovery".
- The root contains every other listed folder, so VS Code indexes those files twice and search reports each hit twice. Measured on `ws-myx-devops`: 3,148 files in the listed folders, 8,768 under the root, of which 5,577 are `.local`. `files.exclude`/`search.exclude` patterns are matched against each folder separately, so an exclude aimed at the root's copy does not affect the nested folders' own listings.

## `ListProjectSequence` takes a project name, and the bare script reads a different input mode

- It takes a project name. A bare basename such as `myx.distro-system` resolves; a true provide-name such as `os.any` or `build-tool:pack.jar` prints `⛔ ERROR: No matching projects is found`. Consumer resolution goes through the provides index instead — `ListDistroProjects --provides <name>`.
- The trap is a name that is both a project name and a provide-name. It resolves, so the argument kind is never questioned, and the next call against a name that is only a provide-name then reads as a defect in that project rather than as the wrong kind of argument.
- Run it through the console, never as a bare script. The bare `ListProjectSequence.fn.sh` resolves `--distro-from-cached` where the console resolves `--distro-from-source`, and it under-reports without saying so. From the workspace root: `echo "Distro ListProjectSequence --no-cache <project>" | ./DistroSourceConsole.sh --non-interactive`, with `--no-cache` ahead of the project name.
- An empty source-mode index, and a call answering exit 0 with an empty sequence, were both observed on `ws-myx.prv-farm`. Neither reproduced on `ws-myx-devops`, where every call answered with real data. Treat them as a workspace state to check for, never as a property of the tool.
- An unindexed project answers exactly as a project with no dependencies does — exit 0, empty sequence — so nothing in the result separates the two. Assert on a non-empty sequence for a project known to carry one.
- `image-prepare:sync-source-files:<sourceName>:…` takes three source forms. `.` is the declaring project's own files; `*` and `**` both walk the selected project's build sequence, `**` taking every project in it that holds the path and `*` only those whose own sequence contains the declaring project. `README.md` documents the directive and none of the three.
- Severing a project from the graph is two conditions, not one: a `Requires:` line removed, **and** the project out of the build sequence. While it remains in the sequence its `data/` files still arrive through any `image-prepare:sync-source-files:**:…` harvest.

## `Augments:` and `Suggests:` gate nothing

- `README.md` states it for both: `Augments:` is a soft dependency hint that does not gate builds, `Suggests:` is informational only.
- The shell parser, `sh-lib/source-prepare/ParseSourceProjectInfToCached.fn.include`, drops both silently and emits no file for either. The awk and Java parsers index `Augments` and nothing reads that index back.
- There is no non-forking specialisation mechanism behind either key. A project that needs to vary a base is forked or sequenced, never augmented.
- `Includes:` and `Builders:` are not keys of this schema at all — neither appears in the `README.md` property list, and neither occurs in any `project.inf` in the tree. A pipeline builder is discovered by path, per "Builders" above, never declared by a key.

## `SourceConsole.include`'s prompt hook applies nothing

- The `--shell-prompt` arm reads `MDSC_INT_CD`, `cd`s to it and clears it, and cannot change the console's working directory: the `Source()` wrapper sources this include inside `( … )` and `PROMPT_COMMAND` calls that wrapper inside `$( … )`, so both statements run two subshells below the interactive shell. The arm announces the change on stderr before applying nothing, which is why it reads as working.
- Full finding, with both controls and the boundary of what was measured: `myx.distro-.local/MAGIC.md`, "The prompt hook announces a change it cannot apply" — read there, not duplicated here.

## `CleanAllOutputs.fn.sh` clears the deploy tier along with the build outputs

- It removes `$MMDAPP/{output,cached,export,distro}`, `.local/{source-cache,output-cache,system-index}` and `.local/temp/javac`. `source/` is untouched, and the script requires it to exist before doing anything.
- **`$MMDAPP/output` is deploy staging, not a rebuildable cache.** Deploy hard-errors without it — `myx.distro-deploy/sh-scripts/DeployProjectSsh.fn.sh:364` and `:495`, `InstallPrepareFiles.fn.sh:344` and `:352`. Clearing outputs therefore clears the deploy tier, which the name does not suggest. That is the consequence to know before running it.
- It takes no confirmation and no `--force`, and its tail runs on a bare invocation. Appropriate for a tool named for exactly what it clears, and recorded as behaviour rather than as a defect: this family states no confirmation convention for destructive operations anywhere.
