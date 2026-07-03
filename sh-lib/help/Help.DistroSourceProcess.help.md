📘 syntax: DistroSourceProcess.fn.sh --ingest-distro-index-from-cached
📘 syntax: DistroSourceProcess.fn.sh <option>

##  Arguments:

		None. This command is option-driven.

##  Options:

		--ingest-distro-output-from-cached
			Syncs cached prepared output into output-cache distro state.

		--ingest-distro-index-from-processed
			Publishes processed output-cache index data to system index.

		--ingest-distro-index-from-cached
			Runs output ingest and then index ingest in sequence.

		--rebuild-output-index
			Rebuilds output index and refreshes derived index files.

		--clone-prepared-metadata
			Clones prepared metadata into output-cache distro state.

		--help
			Prints command help and exits.

		--help-syntax
			Prints syntax summary and exits.

##  Examples (in Local Console, within workspace context):

		# Run cached output ingest and publish system index
		`DistroSourceProcess.fn.sh --ingest-distro-index-from-cached`
		# Clone prepared metadata into output-cache distro state
		`DistroSourceProcess.fn.sh --clone-prepared-metadata`

##  Examples (in OS default shell):

		# Show DistroSourceProcess help from the OS shell
		`bash .local/myx/myx.distro-source/sh-scripts/DistroSourceProcess.fn.sh --help`
