# myx.distro-source

Builds a distro image from a workspace source tree. It scans projects, resolves
what each one requires and provides, runs their builders stage by stage, and
produces the indices and export packages that `myx.distro-deploy` installs.

Use it in a workspace where you edit project sources and keep the index current.

## First command

Open the source console, then pull every configured source repository:

	./DistroSourceConsole.sh
	Distro DistroImageSync --all-tasks --execute-source-prepare-pull

## Ingest, not build

Day to day, pick up a source edit with an ingest:

	DistroSourcePrepare.fn.sh --ingest-distro-index-from-source

A full build, `BuildDistroFromSource.fn.sh`, prepares deploy output and is not the everyday step. An ingest that exits 0 may have changed nothing. [Troubleshooting](docs/troubleshooting.md) explains why.

## Documentation

- [Installation](docs/installation.md) — requirements, install, upgrade and uninstall.
- [Configuration](docs/configuration.md) — settings, profile options and configuration commands.
- [Use](docs/use.md) — getting started, common tasks and selecting what to act on.
- [Commands](docs/commands.md) — the command reference.
- [Formats](docs/formats.md) — file formats, directives, stages and folder layout.
- [Extension](docs/extension.md) — adding your own members, builders, directives and commands.
- [Examples](docs/examples.md) — worked examples from start to finish.
- [Troubleshooting](docs/troubleshooting.md) — symptoms, causes and actions.

## Getting help

- `<Tool>.fn.sh --help` — full syntax, options and examples for any command above.
- `Source --help` — source-context dispatcher syntax.
- Press TAB after a command name and a space for shell completion — this is how to see
  every command the console offers.

## Related packages

- [myx.distro](https://github.com/myx/myx.distro) — the distro system overview.
- [myx.distro-.local](https://github.com/myx/myx.distro-.local) — install and launch the toolsets.
- [myx.distro-system](https://github.com/myx/myx.distro-system) — shared indexing and query tools.
- [myx.distro-deploy](https://github.com/myx/myx.distro-deploy) — deploy a distro image to hosts.
- [myx.distro-remote](https://github.com/myx/myx.distro-remote) — drive a workspace on another machine.
- [myx.distro-agents](https://github.com/myx/myx.distro-agents) — the magic-team agents and their tooling.
