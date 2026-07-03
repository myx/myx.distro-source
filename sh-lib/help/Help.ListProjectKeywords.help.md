📘 syntax: ListProjectKeywords.fn.sh <project_name> [--print-project|--print-no-project] [--merge-sequence] [--filter-and-cut <filter_by>]
📘 syntax: ListProjectKeywords.fn.sh [--help]

##  Summary:

		Prints keywords index values for a project, with optional merged sequence view and
		filter/cut transforms.

##  Arguments:

		project_name
			Required positional argument at position 1 unless supplied through selector include.

##  Options:

		--print-project
			Prints project name column with values.

		--print-no-project
		--print-keywords-only
			Prints values only.

		--merge-sequence
			Uses merged sequence keywords view.

		--filter-and-cut <filter_by>
			Keeps rows matching prefix and strips that prefix from output.

		--help
			Prints command help and exits.

##  Examples:

					# List all keywords for a project (plain output)
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common`

					# List keywords with project name column
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --print-project`

					# List keywords for a platform variant with project name column
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project`

					# List keywords for a project using merged sequence view
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --merge-sequence`

					# List merged-sequence keywords with project name column
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --merge-sequence`

					# Filter keywords by prefix and strip the prefix from output
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --filter-and-cut deploy-export`

					# Filter keywords by prefix, values only (no project column)
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common --print-no-project --filter-and-cut deploy-export`

					# Filter merged-sequence keywords by prefix with project column
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --filter-and-cut deploy-export --merge-sequence`

					# Filter merged-sequence keywords, print-project and print-no-project combined
				`ListProjectKeywords.fn.sh myx/myx.common/os-myx.common-freebsd --print-project --print-no-project --filter-and-cut deploy-export --merge-sequence`

					# List keywords for a host-specific project with project name column
				`ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project`

					# List merged-sequence keywords for a host project with project name column
				`ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --print-project --merge-sequence`

					# Same as above with flags in different order
				`ListProjectKeywords.fn.sh prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --no-cache --no-index --merge-sequence --print-project`
		`ListProjectKeywords.fn.sh --help`
