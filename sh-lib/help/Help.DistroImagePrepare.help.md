📘 syntax: DistroImagePrepare.fn.sh --ingest-distro-index-from-processed
📘 syntax: DistroImagePrepare.fn.sh <option>

	Options:

		--ingest-distro-image-from-git
			Reserved/placeholder option for git-based image ingest.

		--ingest-distro-image-from-output
			Ingests distro image metadata from output cache/state.

		--ingest-distro-index-from-processed
			Publishes processed output-cache index data to the system index.

		--rebuild-cached-index
			Rebuilds cached distro index and refreshes derived index files.

	Examples (in Local Console, within workspace context):

		DistroImagePrepare.fn.sh --ingest-distro-index-from-processed
		DistroImagePrepare.fn.sh --rebuild-cached-index

	Examples (in OS default shell):

		bash .local/myx/myx.distro-source/sh-scripts/DistroImagePrepare.fn.sh --help
