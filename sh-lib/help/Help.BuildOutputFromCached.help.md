📘 syntax: BuildOutputFromCached.fn.sh [--continue]
📘 syntax: BuildOutputFromCached.fn.sh [--help|--help-syntax]

##  Summary:

		Build stage 2: runs source-process builders on prepared cache and produces processed
		output in .local/output-cache.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--continue
			Continues processing remaining builders after a
			builder failure.

		--help
			Prints command help and exits before running stage 2.

		--help-syntax
			Prints syntax summary and exits.

##  Examples:

		# Run prepared->output stage with fail-fast behavior
		`BuildOutputFromCached.fn.sh`

		# Continue running builders after individual failures
		`BuildOutputFromCached.fn.sh --continue`
