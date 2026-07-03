📘 syntax: RebuildKnownHosts.fn.sh [--no-delete]
📘 syntax: RebuildKnownHosts.fn.sh [--help]

##  Summary:

		Regenerates workspace ssh/known_hosts by merging project-level ssh/known_hosts
		entries.

##  Arguments:

		None. This command accepts no positional arguments.

##  Options:

		--no-delete
			Keeps stale known_hosts lines that are not present in current source set.

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Examples:

		# Rebuild workspace known_hosts from project known_hosts files
		`RebuildKnownHosts.fn.sh`

		# Rebuild known_hosts but keep stale records
		`RebuildKnownHosts.fn.sh --no-delete`
