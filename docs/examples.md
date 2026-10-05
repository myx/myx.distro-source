# Examples

[Back to the README](../README.md)

## Pick up a source edit

Print what the build sees as changed, then ingest the change into the index:

	DistroSourcePrepare.fn.sh --scan-source-changes
	DistroSourcePrepare.fn.sh --ingest-distro-index-from-source

## Rebuild from a clean tree

	CleanAllOutputs.fn.sh
	BuildDistroFromSource.fn.sh

To keep going after a builder fails:

	BuildDistroFromSource.fn.sh --continue

## Rebuild only the last stage

	BuildDistroFromSource.fn.sh --only

## Read a project's build sequence

Run the command through the console, with `--no-cache` before the project name:

	echo "Distro ListProjectSequence --no-cache <project>" | ./DistroSourceConsole.sh --non-interactive
