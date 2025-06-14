# myx.distro-source

Default build steps (order in which operations are performed. Source: 1..3, Distro: 4..5):

	1xxx - source-prepare, source to cached (mode: source, stage: prepare) 
				cached contains all sources required to build changed 
				projects and actual meta-data (distro indices: pre-parsed names, 
				reqires, etc...).
	2xxx - source-process, cached to output (mode: source, stage: process)
				output contains all actual meta-data.
	3xxx - image-prepare, output to distro (mode: image, prepare | util)
				distro contains indices and exported items (in their project's locations)
	4xxx - image-process, distro to deploy (mode: image, process | util)
				share repositories
	5xxx - image-install, distro to deploy (mode: image, install | util)
				deploy tasks are executed upon


Project Files & Folders (following masks have fixed meaning in the root folder of each project):

	project.inf - project description file
	actions/** - usable actions (predefined parameters for other scripts)
	source-prepare/builders/1???-* - builders to work on project sets while building source-prepare
	source-process/builders/2???-* - builders to work on project sets while building source-process
	image-prepare/builders/3???-* - builders to work on project sets while building image-prepare
	image-process/builders/4???-* - builders to work on project sets while building image-process
	image-install/builders/5???-* - builders to work on project sets while building image-install
	sh-libs/**
	sh-scripts/**

Builders Examples (actual builders, relative to the root of the workspace):

	source/myx/myx.distro-source/source-prepare/builders/1000-env-from-source.sh
	source/myx/myx.distro-source/source-process/builders/2000-env-from-cached.sh
	source/myx/myx.distro-source/source-process/builders/2899-output-ready.sh
	source/myx/myx.distro-source/image-prepare/builders/3899-distro-ready.sh
	source/myx/myx.distro-distro/image-process/builders/4911-deploy-apply.sh
	source/myx/myx.distro-distro/image-install/builders/5911-deploy-apply.sh

Variables (context environment) available in: actions, build-step scripts and console (source mode):

	MMDAPP - workspace root (something like: "/Volumes/ws-2017/myx-work")
	MDSC_ORIGIN - source of System (Source or Deploy) Console commands (something like: "/Volumes/ws-2017/myx-work/.local/")
	MDSC_INMODE - cosole mode ("source")
	MDSC_OPTION - console mode settings (something like: "--distro-from-source")
	MDSC_SOURCE - current source root (something like: "/Volumes/ws-2017/myx-work/source")
	MDSC_CACHED - current cache root (something like: "/Volumes/ws-2017/myx-work/cached/enhance")
	MDSC_OUTPUT - current target root (something like: "/Volumes/ws-2017/myx-work/cached/source")
	MDSC_DETAIL - debug settings, values: <empty>, "true", "full"
	useSshUser - override from ssh user calculated from project sequence variables
	useSshHome - override from ssh home calculated from project sequence variables
	useSshArgs - extra arguments for ssh conection (something like: "-o ForwardAgent=yes -o AddKeysToAgent=yes")

Variables (context environment) specific to build-step scripts:

	BUILD_STAMP - current build timestamp (build steps only)

App Folders:

	/
	/source - source codes, all repositories and projects
	/source/repo[/group]/project - project tree structure
	/cached - build system space
	/cached/sources - synched source for source->distro builders
	/cached/changed - package names that are changed and need to be built
	/cached/built - package names that are built
	/output - output products
	/distro - distro structure (alternative to /source, BTW)
	/actions - workspace actions - non-editable (generated)


source-prepare, source-process, image-prepare directives:

	image-prepare:context-variable:
		image-prepare:context-variable:<variableName>:{create|change|ensure|insert|update|remove|re-set|delete}[:<valueNoSpaces>...]
		image-prepare:context-variable:<variableName>:{create|change|ensure|append|update|remove|define|delete}[:<valueNoSpaces>...]
		image-prepare:context-variable:<variableName>:{import|source}:{.|<projectName>}:<scriptPath>

		image-prepare:context-variable:DPL_HOST_TYPE:re-set:standalone
		image-prepare:context-variable:DPL_HOST_TYPE:change:guest
		image-prepare:context-variable:DPL_HOST_TYPE:delete
		image-prepare:context-variable:DPL_LANGUAGES:re-set:en
		image-prepare:context-variable:DPL_LANGUAGES:insert:ru
		image-prepare:context-variable:DPL_LANGUAGES:insert:lv
		image-prepare:context-variable:DPL_LANGUAGES:update:en
		image-prepare:context-variable:DPL_LANGUAGES:remove:lv
		image-prepare:context-variable:DPL_LANGUAGES:import:.:ssh/rsa.pub
		image-prepare:context-variable:DPL_LANGUAGES:source:.:ssh/rsa.pub

		^^^ <sourceName> '.' - this (declarant) project's source


	image-prepare:sync-source-files:
		image-prepare:sync-source-files:<sourceName>:<directoryPath>:<targetLocation>[:<filterGlob>]

		image-prepare:sync-source-files:cloud-xdxs/web-mp-js-webapp:src/mpa193:data/settings/web/mp.mcafe.ru
		image-prepare:sync-source-files:cloud-xdxs/web-mp-js-webapp:src/mpa193:data/settings/web/mp.mcafe.ru:*.html
		image-prepare:sync-source-files:.:src/mpa193:data/settings/web/mp.mcafe.ru
		image-prepare:sync-source-files:*:src/mpa193:data/settings/web/mp.mcafe.ru
		image-prepare:sync-source-files:**:src/mpa193:data/settings/web/mp.mcafe.ru

		^^^ <sourceName> '.' - this (declarant) project's source, '*' - this (declarant) and derived projects' sources, '**' - all sequence projects' sources regardless of being derived from declarant

	image-prepare:clone-source-file:
		image-prepare:clone-source-file:<sourceName>:<directoryPath>:<sourceFileName>:<targetNamePattern>:<variableName>:<valueX...>

		image-prepare:clone-source-file:cloud-xdxs/web-mp-js-webapp:src/ndmpa192:page-default.html:page-$$$.html:$$$:200:201:204
		image-prepare:clone-source-file:.:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204
		image-prepare:clone-source-file:*:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204

	image-prepare:source-patch-script:
		image-prepare:source-patch-script:<sourceName>:<sourcePathBase>:<scriptSourceName>:host/scripts/<scriptName>

		image-prepare:source-patch-script:cloud-files/web-mp-jswebapp:mpa193:.:host/scripts/nmp-patch-on-deploy.txt

	image-prepare:target-patch-script:
		image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>
		image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>/*

		image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/settings/web
		image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/www/*
	


Some Commands:

	list all provides (features and deploy data):{
		distro-source.sh --quiet --import-from-source --select-all --print-provides-separate-lines --print ""
		distro-source.sh --quiet --import-from-cached --select-all --print-provides-separate-lines --print ""
		distro-source.sh --quiet --import-from-distro --select-all --print-provides-separate-lines --print ""
		distro-image.sh --output-root ./output --import-from-cached --select-all --print-provides-separate-lines --print ""
		ListDistroProvides.fn.sh --all-provides
	}



### Stage: source-prepare:

The 'distro-source' is:
1. working from 'source' folder
2. builds indices and syncs data to 'cached' folder

At the start of this stage:
1. 'source' folder exists
2. some repositories were configured

At the end of this stage:
1. 'cached' folder exists and updated with changes in 'source' folder
2. shell script (sh, bash) readable basic indices created
3. changed project list updated for '--select-changed' selector
4. source preprocessing directives executed (like source hash or version increment)
5. distro actions updated (without cleaning old ones)


### Stage: source-process:

The 'distro-source' is:
1. working from 'cached' folder
2. builds all data to 'output' folder

At the start of this stage:
1. 'cached' folder exists
2. changed project list updated for '--select-changed' selector

At the end of this stage:
1. 'output' folder exists
2. distro-image indices created
3. packages preprocessed and build
4. export packages and repository contents updated
5. distro actions updated (without cleaning old ones)


### Stage: image-prepare:

See: [distro-deploy](https://github.com/myx/myx.distro-deploy?tab=readme-ov-file#myxdistro-deploy)

The 'distro-deploy' could be updated/cloned from compiled version without pulling and processing source files.

(todo) During this stage one of the following actions available:
- `DistroImageDownload` -- fetch published pre-built images (command provided by 'distro-deploy')
- `DistroImagePublish` -- export images pre-built locally (command provided by 'distro-source')

The 'distro-source' is:
1. working from 'output' folder
2. exporting (pushing and syncing) all export packages built from sources
3. replaces distro actions with new ones (clearing stale actions)


### Stage: image-process:

See: [distro-deploy](https://github.com/myx/myx.distro-deploy?tab=readme-ov-file#myxdistro-deploy)


### Stage: image-install:

See: [distro-deploy](https://github.com/myx/myx.distro-deploy?tab=readme-ov-file#myxdistro-deploy)


