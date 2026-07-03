📘 syntax: DistroSourcePrepare.fn.sh --ingest-distro-index-from-source
📘 syntax: DistroSourcePrepare.fn.sh <option>

##  Options:

		--scan-source-projects
			Lists/collects projects from source roots.

		--scan-source-namespaces
			Lists/collects source namespaces from source roots.

		--scan-source-changes
			Scans repositories/projects and outputs detected source changes.

		--sync-cached-from-source
			Syncs source changes into source-cache/prepare state.

		--ingest-distro-index-from-prepared
			Publishes prepared source-cache index data to system index.

		--ingest-distro-index-from-source
			Runs sync-from-source and ingest-from-prepared in sequence.

		--rebuild-cached-index
			Rebuilds cached distro index and refreshes derived index files.

		--build-project-metadata
			Builds project-level metadata (declares/keywords/provides/requires/sequence).

		--help
		--help-syntax
			Prints command help and syntax information.

##  Examples (in Local Console, within workspace context):

		# Scan source repositories and print changed inputs
		`DistroSourcePrepare.fn.sh --scan-source-changes`
		# Run full source ingest pipeline (sync + publish)
		`DistroSourcePrepare.fn.sh --ingest-distro-index-from-source`

##  Examples (in OS default shell):

		# Show DistroSourcePrepare help from the OS shell
		`bash .local/myx/myx.distro-source/sh-scripts/DistroSourcePrepare.fn.sh --help`
