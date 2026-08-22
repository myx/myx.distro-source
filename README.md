# myx.distro-source

Builds a distro image from a workspace source tree. It scans projects, resolves
what each one requires and provides, runs their builders stage by stage, and
produces the indices and export packages that `myx.distro-deploy` installs.

## Getting started

Install the source toolset into a workspace, then open the source console:

	bash .local/myx/myx.distro-.local/sh-scripts/DistroLocalTools.fn.sh --install-distro-source
	./DistroSourceConsole.sh

Inside the console, call a tool by its full name (`.fn.sh` included), or through
the `Source` or `Distro` dispatcher:

	DistroSourcePrepare.fn.sh --ingest-distro-index-from-source
	Distro DistroSourcePrepare --ingest-distro-index-from-source

Run one command without an interactive session:

	echo "Distro DistroImageSync --all-tasks --execute-source-prepare-pull" \
		| ./DistroSourceConsole.sh --non-interactive

## Common tasks

Pull every configured source repository:

	Distro DistroImageSync --all-tasks --execute-source-prepare-pull

Pick up a local source edit — the narrow, everyday command. It syncs the changed
projects into the cache and republishes the index, naming each project it
touched:

	DistroSourcePrepare.fn.sh --ingest-distro-index-from-source

See what the build considers changed before running anything:

	DistroSourcePrepare.fn.sh --scan-source-changes
	ListChangedSourceProjects.fn.sh

Build the whole pipeline, source through distro:

	BuildDistroFromSource.fn.sh

Rebuild only the final output-to-distro stage:

	BuildDistroFromSource.fn.sh --only

Keep going after a builder fails, instead of stopping at the first error:

	BuildDistroFromSource.fn.sh --continue

Regenerate the workspace `actions/` directory from per-project actions:

	RebuildActions.fn.sh

Clone or update one project from git:

	SyncGitSource.fn.sh <project-name> <git-repository-spec>

Start over from a clean tree:

	CleanAllOutputs.fn.sh

Ingesting source changes is not the same as building the distro. Use
`DistroSourcePrepare` to refresh the index after an edit, and
`BuildDistroFromSource` to produce deploy-ready output.

## Build stages

Five stages run in order. Stages 1–3 belong to source, 4–5 to deploy.

| Stage | Builders | Reads | Writes |
| --- | --- | --- | --- |
| `source-prepare` | `1???-*` | `source` | `cached` — sources and metadata for changed projects |
| `source-process` | `2???-*` | `cached` | `output` — current metadata and built packages |
| `image-prepare` | `3???-*` | `output` | `distro` — indices and exported items |
| `image-process` | `4???-*` | `distro` | deploy — shared repositories |
| `image-install` | `5???-*` | `distro` | deploy — deploy tasks executed |

`myx.distro-deploy` documents the last two stages.

## Project layout

These names have fixed meaning in a project's root folder:

	project.inf                     project description file
	actions/**                      workspace actions this project contributes
	builders/source-prepare/1???-*  builders run during source-prepare
	builders/source-process/2???-*  builders run during source-process
	builders/image-prepare/3???-*   builders run during image-prepare
	builders/image-process/4???-*   builders run during image-process
	builders/image-install/5???-*   builders run during image-install
	sh-libs/**                      shell includes
	sh-scripts/**                   shell commands added to the console PATH

Workspace folders:

	/source                         source code, all repositories and projects
	/source/repo[/group]/project    project tree structure
	/export                         export resources, generated or cloned
	/distro                         distro structure: indices and exported items
	/actions                        generated workspace actions, not editable
	/.local                         installed tools and system integrations
	/.local/distro-index            generated system index
	/.local/source-cache            build cache, written before source-prepare
	/.local/source-cache/sources    synced sources for source-to-distro builders
	/.local/source-cache/changed    names of projects that need rebuilding
	/.local/output-cache            generated output products

## project.inf properties

	Name        project name; matches the folder name, path/group included
	Title       one-line human description
	Requires    other projects or Provides values this project depends on
	Provides    values inherited by every project that Requires this one
	Declares    values that apply to this project only, never inherited
	Keywords    search terms for --select-keywords selectors
	Augments    soft dependency hint; does not gate builds
	Suggests    optional related projects, informational only
	Replaces    projects this one supersedes

Example:

	Name: myx.distro-source
	Title: Distro builder package, prepare distro indices
	Augments: developer-sdk:recommended
	Provides: myx/myx.distro-source distro-source
	Declares: \
		distro-image-sync:source-prepare-pull:repo:myx/myx.distro-source::git@github.com:myx/myx.distro-source.git \

Backslashes continue a value across lines. For the full file grammar — escaping,
continuation, encoding — read
`.local/myx/myx.distro-.local/sh-lib/help/Man.Project.Inf.file.help.md`.

## image-prepare directives

Put these in a project's `Declares` to shape what image-prepare produces.

Set a context variable:

	image-prepare:context-variable:<name>:{create|change|ensure|insert|append|update|remove|re-set|define|delete}[:<value>...]
	image-prepare:context-variable:<name>:{import|source}:{.|<projectName>}:<scriptPath>

	image-prepare:context-variable:HOST_TYPE:re-set:standalone
	image-prepare:context-variable:LANGUAGES:insert:en
	image-prepare:context-variable:LANGUAGES:remove:lv
	image-prepare:context-variable:LANGUAGES:import:.:ssh/rsa.pub

Copy source files into the image:

	image-prepare:sync-source-files:<sourceName>:<directoryPath>:<targetLocation>[:<filterGlob>]

	image-prepare:sync-source-files:.:src/webapp:data/settings/web
	image-prepare:sync-source-files:.:src/webapp:data/settings/web:*.html
	image-prepare:sync-source-files:example/web-app:src/webapp:data/settings/web

Clone one source file into many, substituting a placeholder:

	image-prepare:clone-source-file:<sourceName>:<directoryPath>:<sourceFileName>:<targetNamePattern>:<variableName>:<value>...

	image-prepare:clone-source-file:.:src/webapp:page-default.html:page-$$$.html:$$$:200:201:204

Run a patch script over prepared content:

	image-prepare:source-patch-script:<sourceName>:<sourcePathBase>:<scriptSourceName>:host/scripts/<scriptName>
	image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>[/*]

	image-prepare:source-patch-script:example/web-app:webapp:.:host/scripts/patch-on-deploy.txt
	image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/settings/web

`<sourceName>` selects whose sources a directive reads:

	.    this project's own source
	*    this project and projects derived from it
	**   every project in the sequence, derived or not

## Commands

Pipeline:

- `BuildDistroFromSource.fn.sh` — run the full pipeline through to distro and export artifacts.
- `BuildCachedFromSource.fn.sh` — stage 1 only: source into `.local/source-cache/prepare`.
- `BuildOutputFromCached.fn.sh` — stage 2 only: prepared cache into `.local/output-cache`.
- `DistroSourcePrepare.fn.sh` — scan, sync and ingest source changes into the index.
- `DistroSourceProcess.fn.sh` — ingest processed output into the index.
- `DistroImagePrepare.fn.sh` — ingest image metadata and publish the processed index.

Inspect:

- `ListChangedSourceProjects.fn.sh` — projects marked changed for the next build.
- `ListProjectSequence.fn.sh` — build sequence for one project.
- `ListProjectDependants.fn.sh` — projects that depend on one project.
- `ListProjectProvides.fn.sh` — `Provides` values for one project.
- `ListProjectDeclares.fn.sh` — `Declares` values for one project.
- `ListProjectKeywords.fn.sh` — `Keywords` values for one project.

Maintain:

- `DistroSourceTools.fn.sh` — register namespace roots, set workspace options, upgrade source tools.
- `SyncGitSource.fn.sh` — clone or update one project from git.
- `RebuildActions.fn.sh` — regenerate the workspace `actions/` directory.
- `RebuildKnownHosts.fn.sh` — regenerate workspace `ssh/known_hosts` from project entries.
- `CompileCachedJavaProject.fn.sh` — compile Java sources for one cached project.
- `CompileCachedJavaRepository.fn.sh` — compile Java sources for a whole cached repository.

Clean:

- `CleanAllOutputs.fn.sh` — remove every generated artifact and cache.
- `CleanSourceToCached.fn.sh` — remove source-cache artifacts.
- `CleanCachedToOutput.fn.sh` — remove output-stage artifacts, keep source caches.
- `CleanOutputToDistro.fn.sh` — remove `export` and `distro`, keep earlier stages.
- `CleanSourceFileJunk.fn.sh` — remove OS junk files and extended attributes from the source tree.

## Getting help

- `<Tool>.fn.sh --help` prints full syntax, options and examples for any command above.
- `Help.fn.sh --all` lists every source command.
- `Source --help` prints the source-context dispatcher syntax.
- Press TAB after a command name and a space for shell completion.

## Related packages

- [myx.distro](https://github.com/myx/myx.distro) — the distro system overview.
- [myx.distro-.local](https://github.com/myx/myx.distro-.local) — install and launch the toolsets.
- [myx.distro-system](https://github.com/myx/myx.distro-system) — shared indexing and query tools.
- [myx.distro-deploy](https://github.com/myx/myx.distro-deploy) — deploy a distro image to hosts.
- [myx.distro-remote](https://github.com/myx/myx.distro-remote) — drive a workspace on another machine.
