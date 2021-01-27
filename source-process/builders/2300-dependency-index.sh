
# Require PrepareRepositorySyncToCached
Require DistroSourceCommand

PrepareBuildDependencyIndex(){
	mkdir -p "$MMDAPP/output/distro"
	
	# Require CompileCachedJavaProject
	# CompileCachedJavaProject myx/myx.distro-deploy
	
	# if [ "0" = "1" ] ; then
	
	##
	## temp? fix - java runtime compile doesn't work 
	##
	echo "Making java distro classes..." >&2
	
	local projectList="myx/myx.distro-source myx/myx.distro-deploy"
	local javaClassPath=""
	local javaSourcePath=""
	local projectName projectClasses projectSources
	for projectName in $projectList ; do
		local projectClasses="$MMDAPP/output/cached/$projectName/java"
		local projectSources="$MMDAPP/cached/sources/$projectName/java"
		local javaClassPath="$projectClasses;$javaClassPath"
		local javaSourcePath="$projectSources;$javaSourcePath"
	done
	[ -z "$javaClassPath" ] || local javaClassPath="$javaClassPath\""
	[ -z "$javaSourcePath" ] || local javaSourcePath="$javaSourcePath\""

	for projectName in $projectList ; do
		local projectClasses="$MMDAPP/output/cached/$projectName/java"
		local projectSources="$MMDAPP/cached/sources/$projectName/java"
		local projectQueue="$( find "$projectSources" -type f -name '*.java' | sed 's|$projectSources||g' )"
		if [ ! -z "${projectQueue:0:1}" ] ; then
			local checkSourceFile checkClassFile
			local sourceFilesQueue="$( \
				echo "$projectQueue" \
				| while read -r checkSourceFile ; do
					checkClassFile="$projectClasses${checkSourceFile%'.java'}.class"
					if [ ! -f "$checkClassFile" ] || [ "$checkSourceFile" -nt "$checkClassFile" ] ; then
						printf "$checkSourceFile "
					fi
				done
			)" 
			if [ ! -z "$sourceFilesQueue" ] ; then
				echo "Compiling: $projectName..." >&2
				javac -nowarn -d "$projectClasses" -classpath "$javaClassPath" -sourcepath "$javaSourcePath" -g -parameters $sourceFilesQueue || true
				echo "javac -nowarn -d '$projectClasses' -classpath $javaClassPath -sourcepath "$javaSourcePath" -g -parameters $sourceFilesQueue 2> /dev/null || true"
				echo "Done compiling: $projectName." >&2
			fi
		fi
	done

	echo "Done making java distro classes." >&2
	##
	## /end
	##
	
	# fi
	
	( \
		DistroSourceCommand \
			-v \
			--source-root "$MMDAPP/cached/sources" \
			--output-root "$MMDAPP/output" \
			--import-from-source --select-all-from-source \
			--print ''  -vv \
			--build-all \
			--print '' \
	)
}

PrepareBuildDependencyIndex

