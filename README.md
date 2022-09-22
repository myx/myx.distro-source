# myx.distro-source



source-prepare, source-process, image-prepare commands:

	image-prepare:context-variable:<variableName>:{create|change|ensure|insert|update|remove|re-set|delete}[:<valueNoSpaces>...]
	image-prepare:context-variable:<variableName>:{create|change|ensure|append|update|remove|define|delete}[:<valueNoSpaces>...]
	image-prepare:context-variable:DPL_HOST_TYPE:re-set:standalone
	image-prepare:context-variable:DPL_HOST_TYPE:change:guest
	image-prepare:context-variable:DPL_HOST_TYPE:delete
	image-prepare:context-variable:DPL_LANGUAGES:re-set:en
	image-prepare:context-variable:DPL_LANGUAGES:insert:ru
	image-prepare:context-variable:DPL_LANGUAGES:insert:lv
	image-prepare:context-variable:DPL_LANGUAGES:update:en
	image-prepare:context-variable:DPL_LANGUAGES:remove:lv

	image-prepare:sync-source-files:<sourceName>:<directoryPath>:<targetLocation>[:<filterGlob>]
	image-prepare:sync-source-files:cloud-xdxs/web-mp-js-webapp:src/mpa193:data/settings/web/mp.mcafe.ru
	image-prepare:sync-source-files:cloud-xdxs/web-mp-js-webapp:src/mpa193:data/settings/web/mp.mcafe.ru:*.html
	image-prepare:sync-source-files:.:src/mpa193:data/settings/web/mp.mcafe.ru
	image-prepare:sync-source-files:*:src/mpa193:data/settings/web/mp.mcafe.ru
	image-prepare:sync-source-files:**:src/mpa193:data/settings/web/mp.mcafe.ru

	^^^ <sourceName> '.' - this (declarant) project's source, '*' - this (declarant) and derived projects' sources, '**' - all sequence projects' sources regardless of being derived from declarant

	image-prepare:clone-source-file:<sourceName>:<directoryPath>:<sourceFileName>:<targetNamePattern>:<variableName>:<valueX...>
	image-prepare:clone-source-file:cloud-xdxs/web-mp-js-webapp:src/ndmpa192:page-default.html:page-$$$.html:$$$:200:201:204
	image-prepare:clone-source-file:.:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204
	image-prepare:clone-source-file:*:src/mpa192:page-default.html:page-$$$.html:$$$:200:201:204

	image-prepare:source-patch-script:<sourceName>:<sourcePathBase>:<scriptSourceName>:host/scripts/<scriptName>
	image-prepare:source-patch-script:cloud-files/web-mp-jswebapp:mpa193:.:host/scripts/nmp-patch-on-deploy.txt

	image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>
	image-prepare:target-patch-script:<scriptSourceName>:host/scripts/<scriptName>:<targetDeployPath>/*
	image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/settings/web
	image-prepare:target-patch-script:.:host/scripts/patch-on-deploy.txt:/data/www/*
	