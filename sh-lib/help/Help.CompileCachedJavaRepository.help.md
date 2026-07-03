📘 syntax: CompileCachedJavaRepository.fn.sh <repository-name>
📘 syntax: CompileCachedJavaRepository.fn.sh [--help]

##  Summary:

		Compiles Java sources for all projects in selected repository inside cached build
		workspace.

##  Arguments:

		repository-name
			Repository key (for example, lib or myx) to compile from cache.

##  Options:

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Examples:

		# Compile cached Java sources for repository 'myx'
		`CompileCachedJavaRepository.fn.sh myx`

		# Compile cached Java sources for repository 'lib'
		`CompileCachedJavaRepository.fn.sh lib`
