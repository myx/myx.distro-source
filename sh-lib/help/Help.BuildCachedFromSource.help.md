📘 syntax: BuildCachedFromSource.fn.sh [--continue]
📘 syntax: BuildCachedFromSource.fn.sh [--help|--help-syntax]

##  Summary:

		Build stage 1: ingests source projects and runs source-prepare builders to produce
		.local/source-cache/prepare for downstream stages.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--continue
			Continues processing remaining builders after a
			builder failure.

		--help
			Prints command help and exits before running stage 1.

		--help-syntax
			Prints syntax summary and exits.

##  Examples:

		# Run source->prepared stage with fail-fast behavior
		`BuildCachedFromSource.fn.sh`

		# Continue running builders after individual failures
		`BuildCachedFromSource.fn.sh --continue`
