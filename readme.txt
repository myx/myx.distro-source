To re-create workspace environment do the following:
1) create a work directory
2) run:
	2.1) 'curl ' on mac
	2.2) 'fetch ' on bsd
3) run:
	source-prepare-build


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




