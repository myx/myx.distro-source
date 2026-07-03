📘 syntax: RebuildActions.fn.sh [--no-delete]
📘 syntax: RebuildActions.fn.sh [--test1|--test2|--test3]
📘 syntax: RebuildActions.fn.sh [--help]

##  Summary:

		Regenerates top-level actions directory from per-project actions scripts discovered
		in source.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--no-delete
			Keeps stale generated action files not present in current source index.

		--test1
		--test2
		--test3
			Internal test/debug modes for action discovery.

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Examples:

		# Rebuild actions and delete stale generated entries
		`RebuildActions.fn.sh`

		# Rebuild actions but keep stale entries
		`RebuildActions.fn.sh --no-delete`
