📘 syntax: ListProjectDependants.fn.sh <project-name> [--no-cache]
📘 syntax: ListProjectDependants.fn.sh [--help]

##  Summary:

		Lists projects that depend on selected project, using cached dependency/index
		metadata.

##  Arguments:

		project-name
			Project to query reverse dependencies for.

##  Options:

		--no-cache
			Bypasses cached dependant list and rebuilds from current index metadata.

		--help
			Prints command help and exits.

		--help-syntax
			Prints command syntax summary and exits.

##  Notes:

		Command parsing also accepts standard context/project selector options from
		SystemContext.UseStandardOptionsRequireProject.include.

##  Examples:

                # List dependants of a host-setup project using distro-source index
                `ListProjectDependants.fn.sh --distro-source-only ndm/cloud.knt/setup.host-ndss111r3.example.org`

                # List dependants using full distro-from-source resolution
                `ListProjectDependants.fn.sh --distro-from-source ndm/cloud.knt/setup.host-ndss111r3.example.org`

                # List dependants for an infrastructure project, suppress errors if none found
                `ListProjectDependants.fn.sh --distro-source-only ndm/cloud-infra/setup.assets-infra/location-r4 2> /dev/null`


		# Typical function-level usage via dispatcher
		`Distro ListProjectDependants myx/myx.distro-system --no-cache`
