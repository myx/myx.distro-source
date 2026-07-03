📘 syntax: ListProjectSequence.fn.sh [--no-cache] <project_name> [--print-project] [--print-{provides|declares|keywords}]
📘 syntax: ListProjectSequence.fn.sh [--help]

##  Summary:

		Prints project sequence and related index views for one project.

##  Arguments:

		project_name
			Required positional argument at position 1.

##  Options:

		--print-project
			Prefixes each output row with original project name.

		--print-provides
		--print-declares
		--print-keywords
			Prints merged values for selected index family.

		--no-cache
			Bypasses cache in included selector/index helpers.

		--help
			Prints command help and exits.
