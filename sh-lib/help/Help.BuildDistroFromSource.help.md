📘 syntax: BuildDistroFromSource.fn.sh [--continue]
📘 syntax: BuildDistroFromSource.fn.sh [--only|--build-distro-from-output] [--continue]
📘 syntax: BuildDistroFromSource.fn.sh [--help|--help-syntax]

##  Summary:

		Orchestrates the full build pipeline from source ingest to final distro/export
		artifacts.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--continue
			Continues processing remaining builders after a
			builder failure.

		--only
		--build-distro-from-output
			Flags, take no value. Runs only final output-to-distro stage and skips
			source/cached/output pre-stages.

		--help
			Prints command help and exits before running any stage.

		--help-syntax
			Prints syntax summary and exits.

##  Examples:

		# Run full pipeline: source -> cached -> output -> distro
		`BuildDistroFromSource.fn.sh`

		# Run only final output->distro stage
		`BuildDistroFromSource.fn.sh --only`

		# Run full pipeline and continue after builder failures
		`BuildDistroFromSource.fn.sh --continue`
