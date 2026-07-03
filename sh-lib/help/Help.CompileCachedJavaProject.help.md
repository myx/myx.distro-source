📘 syntax: CompileCachedJavaProject.fn.sh <project-name>
📘 syntax: CompileCachedJavaProject.fn.sh --project-from-env
📘 syntax: CompileCachedJavaProject.fn.sh --project-from-pwd
📘 syntax: CompileCachedJavaProject.fn.sh [--help]

##  Summary:

		Compiles Java sources for one project in cached workspace used by distro
		source-build pipeline.

##  Arguments:

		project-name
			Project path/name in distro source index.

##  Options:

		--project-from-env
			Resolves project from MDSC_PRJ_NAME.

		--project-from-pwd
			Resolves project from current working directory.

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Examples:

		# Compile a specific project by name
		`CompileCachedJavaProject.fn.sh myx/myx.distro-system`

		# Compile project resolved from MDSC_PRJ_NAME
		`CompileCachedJavaProject.fn.sh --project-from-env`

		# Compile project resolved from current directory
		`CompileCachedJavaProject.fn.sh --project-from-pwd`
