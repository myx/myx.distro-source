📘 syntax: CleanSourceFileJunk.fn.sh [root-path]
📘 syntax: CleanSourceFileJunk.fn.sh [--help|--help-syntax]

##  Summary:

		Removes OS junk files/directories and strips unwanted xattrs in source tree before
		indexing or build.

##  Arguments:

		root-path
			Optional positional argument. Defaults to workspace source directory.

##  Options:

		--help
			Prints command help and exits.

		--help-syntax
			Prints syntax summary and exits.

##  Examples:

		# Clean junk files under default source root
		`CleanSourceFileJunk.fn.sh`

		# Clean junk files under an explicit path
		`CleanSourceFileJunk.fn.sh "$MMDAPP/source/myx"`
