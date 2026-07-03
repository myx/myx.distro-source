📘 syntax: SyncGitSource.fn.sh <project_name> <git-repository-spec>
📘 syntax: SyncGitSource.fn.sh [--help]

##  Summary:

		Clones/updates one source project directory from a git repository.

##  Arguments:

		project_name
			Required positional argument at position 1. Target project path/name under source.

		git-repository-spec
			Required positional argument at position 2. Git remote URL/spec.

##  Options:

		--help
			Prints command help and exits.

##  Notes:

		Script help text historically mentioned optional branch argument, but current parser
		rejects additional positional arguments beyond repository spec.

##  Examples:

		# Sync a project source from its upstream GitHub repository (default branch)
		`SyncGitSource.fn.sh myx/myx.common/os-myx.common git@github.com:myx/os-myx.common.git`

		# Sync a project source from a specific branch
		`SyncGitSource.fn.sh myx/myx.common/os-myx.common git@github.com:myx/os-myx.common.git main`

		# Print command help and exit
		`SyncGitSource.fn.sh --help`
