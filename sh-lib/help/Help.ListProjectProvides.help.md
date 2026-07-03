📘 syntax: ListProjectProvides.fn.sh <project_name> [--print-project|--print-no-project] [--merge-sequence] [--filter-and-cut <filter_by>]
📘 syntax: ListProjectProvides.fn.sh [--help]

##  Summary:

		Prints provides index values for a project, with optional merged sequence view and
		filter/cut transforms.

##  Arguments:

		project_name
			Required positional argument at position 1 unless supplied through selector include.

##  Options:

		--print-project
			Prints project name column with values.

		--print-no-project
		--print-provides-only
			Prints values only.

		--merge-sequence
			Uses merged sequence provides view.

		--filter-and-cut <filter_by>
			Keeps rows matching prefix and strips that prefix from output.

		--help
			Prints command help and exits.

##  Examples:

		# List all provides entries for a project (plain output)
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common`

		# List provides with project name column
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common --print-project`

		# List provides for a platform variant with project name column
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project`

		# List provides for a project using merged sequence view
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence`

		# List merged-sequence provides with project name column
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence`

		# Filter provides by prefix and strip the prefix from output
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export`

		# Filter provides by prefix, values only (no project column)
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common --print-no-project --filter-and-cut deploy-export`

		# Filter merged-sequence provides by prefix with project column
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence`

		# Filter merged-sequence provides, print-project and print-no-project combined
		`ListProjectProvides.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-no-project --filter-and-cut deploy-export --merge-sequence`

		# List provides for a host-specific project with project name column
		`ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project`

		# List merged-sequence provides for a host project with project name column
		`ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence`

		# Same as above with flags in different order
		`ListProjectProvides.fn.sh myx/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project`
		`ListProjectProvides.fn.sh --help`
