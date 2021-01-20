To re-create workspace environment do the following:
1) create a work directory
2) run:
	2.1) 'curl ' on mac
	2.2) 'fetch ' on bsd
3) run:
	source-prepare-build

	
	
App Folders:

/
/source - source codes
/source/repo[/group]/project - structure
/cached - build system space
/cached/sources - synched source for source->distro builders
/cached/changed - package names that are changed and need to be built
/cached/built - package names that are built
/output - output products
/distro - distro structure (alternative to /source, BTW)


Project Files & Folders:

project.inf - project description file
actions/** - usable actions (predefined parameters for other scripts)
source-prepare/builders/* - builders to work on project sets while building source-prepare
source-process/builders/* - builders to work on project sets while building source-process
image-prepare/builders/* - builders to work on project sets while building image-prepare
image-process/builders/* - builders to work on project sets while building image-process
image-install/builders/* - builders to work on project sets while building image-install
sh-libs/**
sh-scripts/**

Default build steps:
	1xxx - source-prepare, source to cached (mode: source, stage: prepare) 
				cached contains all sources required to build changed 
				projects and actual meta-data (distro indices: pre-parsed names, 
				reqires, etc...).
	2xxx - source-process, cached to output (mode: source, stage: prepare)
				output contains and actual meta-data.
	3xxx - image-prepare, output to distro (mode: image, prepare | util)
				distro contains indices and exported items (in their project's locations)
	4xxx - image-process, distro to deploy (prepare | util | install )
				share repositories
	5xxx - image-install, distro to deploy (prepare | util | install )
				deploy tasks are executed upon

2101-install-start-setup-environment

Default 'install' 


----------------
	--source-prepare: \ "source"
	--source-prepare:increment: \
	--source-process: \ "source" -> "cached"
	--source-publish: \ ? --source-process:publish:
	--image-prepare: \ "source" + "cached" -> "distro"
	--image-process: \
	--image-publish: \ ? --image-process:publish:
	--image-receive: \ pull "distro" without having source
	--image-install: \
	--image-upgrade: \
	--deploy-prepare: \
	--deploy-export: \
	--deploy-settings: \
	--deploy-reinstall: \
	--deploy-actions: \
	--execute-remote: \ ? --deploy-settings:execute-command:
	--monitor-checks: \
----------------



Commands:

list all provides (features and deploy data):{
	distro-source.sh --quiet --import-from-source --select-all --print-provides-separate-lines --print ""
	distro-source.sh --quiet --import-from-cached --select-all --print-provides-separate-lines --print ""
	distro-source.sh --quiet --import-from-distro --select-all --print-provides-separate-lines --print ""
	distro-image.sh --output-root ./output --import-from-cached --select-all --print-provides-separate-lines --print ""
	ListDistroProvides.fn.sh --all-provides
}



