# Use

[Back to the README](../README.md)

## Getting started

Open the console first. [Installation](installation.md) shows how.

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

Pick up a local source edit. This is the narrow, everyday command: it syncs the
changed projects into the cache and republishes the index, naming each project it
touched:

	DistroSourcePrepare.fn.sh --ingest-distro-index-from-source

See what the build considers changed, before running anything:

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
