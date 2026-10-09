# Formats

[Back to the README](../README.md)

## Build stages

Six stages run in order. Stages 1–3 belong to source, 4–6 to deploy.

- `source-prepare` — builders `1???-*`. Reads `source`, writes `cached`: the sources
  and metadata needed to build the changed projects.
- `source-process` — builders `2???-*`. Reads `cached`, writes `output`: current
  metadata and built packages.
- `source-publish` — builders `3???-*`. Publishes built sources. Shares the `3???`
  range with `image-prepare`. Each builder runs in its own stage, in step-number order.
  Builders with the same step number run in parallel.
- `image-prepare` — builders `3???-*`. Reads `output`, writes `distro`: indices and
  exported items, in their projects' locations.
- `image-process` — builders `4???-*`. Reads `distro`, shares repositories to deploy.
- `image-install` — builders `5???-*`. Reads `distro`, runs the deploy tasks.

`myx.distro-deploy` documents the last two.

## Project layout

These names have fixed meaning in a project's root folder:

- `project.inf` — the project description file.
- `actions/**` — workspace actions this project contributes.
- `builders/<stage>/<NNNN>-*` — builders run during that stage, in numeric order.
	- `builders/source-prepare/1???-*`
	- `builders/source-process/2???-*`
	- `builders/source-publish/3???-*`
	- `builders/image-prepare/3???-*`
	- `builders/image-process/4???-*`
	- `builders/image-install/5???-*`
- `sh-lib/**` — shell includes.
- `sh-scripts/**` — shell commands added to the console `PATH`.

## Workspace folders

- `/source` — source code, all repositories and projects.
	- `/source/repo[/group]/project` — project tree structure.
- `/export` — export resources, generated or cloned.
- `/distro` — distro structure: indices and exported items.
- `/actions` — generated workspace actions. Not editable.
- `/.local` — installed tools and system integrations.
	- `/.local/system-index` — generated system index.
	- `/.local/source-cache` — build cache, written before source-prepare.
	- `/.local/source-cache/sources` — synced sources for source-to-distro builders.
	- `/.local/source-cache/changed` — names of projects that need rebuilding.
	- `/.local/output-cache` — generated output products.

## project.inf properties

- `Name` — project name; matches the folder name, path and group included.
- `Title` — one-line human description.
- `Requires` — other projects, or `Provides` values, this project depends on.
- `Provides` — values inherited by every project that `Requires` this one.
- `Declares` — values that apply to this project only, never inherited.
- `Keywords` — search terms for `--select-keywords` selectors.
- `Augments` — soft dependency hint. Does not gate builds.
- `Suggests` — optional related projects. Informational only.
- `Replaces` — projects this one supersedes.

Example:

	Name: myx.distro-source
	Title: Distro builder package, prepare distro indices
	Augments: developer-sdk:recommended
	Provides: myx/myx.distro-source distro-source
	Declares: \
		distro-image-sync:source-prepare-pull:repo:myx/myx.distro-source::git@github.com:myx/myx.distro-source.git \

Backslashes continue a value across lines. Carry the backslash on **every**
entry, including the last, and end the list with a blank line — as the example
above does. A list whose last entry has no backslash forces an edit to that line
whenever an entry is added after it, so a one-line addition shows up as a
two-line change and every diff reads as touching a neighbour it did not mean to.

The full file grammar — escaping,
continuation, encoding — is in the
[project.inf file format manual](https://github.com/myx/myx.distro-.local/blob/main/sh-lib/help/Man.Project.Inf.file.help.md).

## image-prepare directives

Put these in a project's `Declares` to shape what image-prepare produces.

- `image-prepare:context-variable:<name>:<operation>[:<value>...]` — set a build
  context variable. Operations: `create`, `change`, `ensure`, `insert`, `append`,
  `update`, `remove`, `re-set`, `define`, `delete`.
	- `image-prepare:context-variable:HOST_TYPE:re-set:standalone`
	- `image-prepare:context-variable:LANGUAGES:insert:en`
	- `image-prepare:context-variable:LANGUAGES:remove:lv`
- `image-prepare:context-variable:<name>:{import|source}:{.|<projectName>}:<scriptPath>` —
  take the value from a file inside a project.
	- `image-prepare:context-variable:HOST_KEY:import:.:ssh/rsa.pub`
- `image-prepare:sync-source-files:<sourceName>:<directoryPath>:<targetLocation>[:<filterGlob>]` —
  copy source files into the image.
	- `image-prepare:sync-source-files:.:src/webapp:data/settings/web`
	- `image-prepare:sync-source-files:.:src/webapp:data/settings/web:*.html`
	- `image-prepare:sync-source-files:example/web-app:src/webapp:data/settings/web`
- `image-prepare:clone-source-file:<sourceName>:<directoryPath>:<sourceFileName>:<targetNamePattern>:<variableName>:<value>...` —
  clone one source file into many, substituting a placeholder.
	- `image-prepare:clone-source-file:.:src/webapp:page-default.html:page-$$$.html:$$$:200:201:204`
- `image-prepare:source-patch-script:<sourceName>:<sourcePathBase>:<scriptSourceName>:host/scripts/<scriptName>` —
  patch prepared content.
	- `image-prepare:source-patch-script:example/web-app:webapp:.:host/scripts/patch-on-deploy.txt`
- `image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>[/*]` —
  patch content at its deploy location.
	- `image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/settings/web`

`<sourceName>` selects whose sources a directive reads:

- `.` — the declaring project's own source.
- `*` and `**` — both walk the build sequence of the selected project.
	- `**` takes every project in that sequence that holds the path.
	- `*` takes only the projects whose own sequence contains the declaring project.


## Stage variables

Each stage script sets `MDSC_SOURCE`, `MDSC_CACHED` and `MDSC_OUTPUT` to its own input and output directories. They are not fixed values. A value read in one stage does not describe another.

- Stage 1, `BuildCachedFromSource`: `MDSC_CACHED` is `.local/source-cache/prepare`.
- Stage 2, `BuildOutputFromCached`: `MDSC_CACHED` is `.local/output-cache/prepared` and `MDSC_OUTPUT` is `.local/output-cache`.
- Outside a stage, where ad-hoc commands run, `MDSC_CACHED` is `.local/system-index`. This is the published index that most everyday commands read.

## Builder files

A builder is found by its path. No `project.inf` key declares it.

- Any project in the index may carry `builders/<stage>/<NNNN>-*.sh`. The tools pick it up.
- Each runner selects exactly one stage.
- Builder file names must be unique across all projects and stages. When two share a name, the listing keeps one and omits the other.
- `Includes:` and `Builders:` are not `project.inf` keys.

## build.number

The builder `1201-increment.sh` keeps a counter in `source/<project>/build.number`. It acts on changed projects whose `Provides` carry both `source-prepare:increment` and `build.number`.

- The file holds one decimal integer and a trailing newline, and nothing else.
- When the file is absent, the builder starts it at `1`.
- Any other content is an error. The builder leaves the file untouched and exits non-zero.
- A project with no uncommitted changes is skipped.
- The builder writes the new value to a temporary file and moves it into place. A failed write never truncates the old value.
- The counter lives in `source/`. It needs no commit or push, because ingest reads the source tree.

What the project does with the number is the project's own business. The pipeline only maintains it.
