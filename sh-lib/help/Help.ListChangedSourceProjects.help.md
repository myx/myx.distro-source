📘 syntax: ListChangedSourceProjects.fn.sh [--no-cache]
📘 syntax: ListChangedSourceProjects.fn.sh [--help]

##  Summary:

		Lists projects currently marked as changed for incremental source rebuild and
		processing.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--no-cache
			Bypasses cached changed-project index and rebuilds result from current markers.

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Examples:

		# List changed projects using cached index when available
		`ListChangedSourceProjects.fn.sh`

		# List changed projects bypassing cache
		`ListChangedSourceProjects.fn.sh --no-cache`
