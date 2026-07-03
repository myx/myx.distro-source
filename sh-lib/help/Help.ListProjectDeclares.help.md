📘 syntax: ListProjectDeclares.fn.sh <project_name> [--print-project|--print-no-project] [--merge-sequence] [--filter-and-cut <filter_by>]
📘 syntax: ListProjectDeclares.fn.sh [--help]

##  Summary:

		Prints declares index values for a project, with optional merged sequence view and
		filter/cut transforms.

##  Arguments:

		project_name
			Required positional argument at position 1 unless supplied through selector include.

##  Options:

		--print-project
			Prints project name column with values.

		--print-no-project
		--print-declares-only
			Prints values only.

		--merge-sequence
			Uses merged sequence declares view.

		--filter-and-cut <filter_by>
			Keeps rows matching prefix and strips that prefix from output.

		--help
			Prints command help and exits.

##  Examples:

					# List all declares entries for a project (plain output)
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common`

					# List declares with project name column
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-project`

					# List declares for a platform variant with project name column
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project`

					# List declares for a project using merged sequence view
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence`

					# List merged-sequence declares with project name column
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence`

					# Filter declares by prefix and strip the prefix from output
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export`

					# Filter declares by prefix, values only (no project column)
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common --print-no-project --filter-and-cut deploy-export`

					# Filter merged-sequence declares by prefix with project column
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence`

					# Filter merged-sequence declares, print-project and print-no-project combined
				`ListProjectDeclares.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-no-project --filter-and-cut deploy-export --merge-sequence`

					# List declares for a host-specific project with project name column
				`ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project`

					# List merged-sequence declares for a host project with project name column
				`ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence`

					# Same as above with flags in different order
				`ListProjectDeclares.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project`
		`ListProjectDeclares.fn.sh --help`
