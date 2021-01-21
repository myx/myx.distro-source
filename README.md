# myx.distro-source



source-prepare, source-process, image-prepare commands:

	image-prepare:sync-source-files:<projectName>:<directoryPath>:<targetLocation>
	image-prepare:sync-source-files:cloud-ndxs/web-ndmp-js-webapp:src/ndmpa193:data/settings/web/ndmp.musicafe.ru
	image-prepare:sync-source-files:.:src/ndmpa193:data/settings/web/ndmp.musicafe.ru
	image-prepare:sync-source-files:*:src/ndmpa193:data/settings/web/ndmp.musicafe.ru

	image-prepare:source-patch-script:<sourceProjectName>:<sourcePathBase>:<scriptProjectName>:host/scripts/<scriptName>
	image-prepare:source-patch-script:cloud-files/web-nmp-jswebapp:mpa193:.:host/scripts/nmp-patch-on-deploy.txt

	image-prepare:clone-source-file:<projectName>:<directoryPath>:<sourceFileName>:<targetNamePattern>:<variableName>:<valueX...>
	image-prepare:clone-source-file:cloud-ndxs/web-ndmp-js-webapp:src/ndmpa192:page-default.html:page-$$$.html:$$$:200:201:204
	image-prepare:clone-source-file:.:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204
	image-prepare:clone-source-file:*:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204

	--image-prepare:target-patch-script:<projectName>:host/scripts/<scriptName>:<targetHostPath>
	--image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/usr/local/myservice/settings
