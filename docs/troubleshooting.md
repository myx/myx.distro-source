# Troubleshooting

[Back to the README](../README.md)

## An ingest ran, exited 0 and changed nothing

`DistroSourcePrepare.fn.sh --sync-cached-from-source` works out the change set again. When that set is empty, it prints `no new changes` on stderr, regenerates nothing and exits 0.

`--ingest-distro-index-from-source` runs that step first, so it behaves the same way. The exit status cannot tell "nothing needed doing" from "the thing you wanted did not happen".

Check the artefact the ingest regenerates. Scan with `--scan-source-changes` to see what the build counts as changed.

## Ingest or build

An ingest refreshes the index after a source edit. A build prepares deploy output without sources. With live sources and a console open, ingest the changes instead of building.

## Rebuild the index

To rebuild the cached index without a full build, run:

	DistroSourcePrepare.fn.sh --rebuild-cached-index

To rebuild the per-project metadata, run `--build-project-metadata`.

## A clean removed more than expected

`CleanAllOutputs.fn.sh` removes these, and it asks no question:

- `output`, `cached`, `export` and `distro` in the workspace root.
- `.local/source-cache`, `.local/output-cache` and `.local/system-index`.
- `.local/temp/javac`.

It leaves `source/` alone, and it needs `source/` to exist. There is no `--force` and no confirmation.

`output` is deploy staging, not a cache you can rebuild at will. Deploy stops with an error when it is missing. Both `CleanAllOutputs.fn.sh` and `CleanCachedToOutput.fn.sh` remove it. Rebuild before you deploy.

To clean less, use the narrowest command. [Commands](commands.md) lists what each one removes.

## A sequence is empty, or a project looks unindexed

An unindexed project answers exactly as a project with no dependencies does. It exits 0 with an empty sequence. Nothing in the answer separates the two.

Ingest the source, then ask again. Assert on a non-empty sequence for a project you know has dependencies.

## ListProjectSequence says no matching projects

`ListProjectSequence` takes a project name. A bare name such as `myx.distro-system` resolves. A provide name such as `os.any` does not, and prints `No matching projects is found`.

To find the projects behind a provide name, use `ListDistroProjects --provides <name>`.

Run it through the console. The bare script reads a different input mode and can under-report without saying so:

	echo "Distro ListProjectSequence --no-cache <project>" | ./DistroSourceConsole.sh --non-interactive

## A removed dependency still delivers files

Cutting a project out of the graph takes two steps:

- Remove its `Requires:` line.
- Take it out of the build sequence.

While it stays in the sequence, an `image-prepare:sync-source-files:**:...` directive still collects its `data/` files.

## Augments or Suggests changes nothing

`Augments:` and `Suggests:` gate nothing. A project that must vary a base is forked or sequenced instead.

## VS Code search shows every hit twice

The generated `.code-workspace` file lists the workspace root as a folder. VS Code chat clients look up workspace-local items, such as agent skills, in each listed folder, and need the root for that.

The root contains the other listed folders, so VS Code indexes their files twice. `files.exclude` and `search.exclude` patterns apply to each folder separately. A pattern aimed at the root does not change the nested folders' own listings.
