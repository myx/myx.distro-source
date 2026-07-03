📘 syntax: Help.fn.sh [--all|--help]

##  Summary:

		Prints top-level command entrypoint synopsis.

##  Arguments:

		None. This command is option-driven.

##  Options:

		--all
			Prints extended synopsis including Require command line.

		--help
			Prints extended synopsis including Require command line.

##  Examples:

				# Show command summary or full list depending on selected option
		`Help.fn.sh [--all|--help]`

				# Use the same entry point to request the complete generated help set
		`Help.fn.sh [--all|--help]`

				# Print command help and exit
		`Help.fn.sh --help`
