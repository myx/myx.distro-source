📘 syntax: BuildDistroFromSource.fn.sh [--continue]
📘 syntax: BuildDistroFromSource.fn.sh [--only|--build-distro-from-output] [--continue]
📘 syntax: BuildDistroFromSource.fn.sh [--help|--help-syntax]

##  Summary:

		Orchestrates the full build pipeline through to the final distro/export
		artifacts.

##  Notes:

		Builds the distro repository, preparing all output for deploy without sources.
		This is not the same operation as ingesting source changes — for that, see
		DistroSourcePrepare.

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
