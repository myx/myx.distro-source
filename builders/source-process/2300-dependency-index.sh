
Require DistroSourceCommand

PrepareBuildDependencyIndex(){
	# Require CompileCachedJavaProject
	# CompileCachedJavaProject myx/myx.distro-deploy
	
	if false ; then
	
	##
	## temp? fix - java runtime compile doesn't work 
	##
	echo "Making java distro classes..." >&2
	
	local projectList="myx/myx.distro-source myx/myx.distro-deploy"
	local javaClassPath= javaSourcePath=
	local projectName projectClasses projectSources
	for projectName in $projectList ; do
		projectClasses="$MMDAPP/.local/output-cache/$projectName/java"
		projectSources="$MMDAPP/.local/source-cache/sources/$projectName/java"
		javaClassPath="$projectClasses:$javaClassPath"
		javaSourcePath="$projectSources:$javaSourcePath"
	done

	for projectName in $projectList ; do
		local projectClasses="$MMDAPP/.local/output-cache/$projectName/java"
		local projectSources="$MMDAPP/.local/source-cache/sources/$projectName/java"
		local projectQueue="$( find "$projectSources" -type f -name '*.java' | sed 's|$projectSources||g' )"
		if [ -n "${projectQueue:0:1}" ] ; then
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
			if [ -n "$sourceFilesQueue" ] ; then
				echo "Compiling: $projectName..." >&2
				javac -nowarn -d "$projectClasses" -classpath "$javaClassPath" -sourcepath "$javaSourcePath" -g -parameters $sourceFilesQueue || :
				echo "javac -nowarn -d "$projectClasses" -classpath "$javaClassPath" -sourcepath "$javaSourcePath" -g -parameters $sourceFilesQueue 2> /dev/null || :"
				echo "Done compiling: $projectName." >&2
			fi
		fi
	done

	echo "Done making java distro classes." >&2
	##
	## /end
	##
	
	fi
	
	(
		DistroSourceCommand \
			-v$( 
				[ -z "$MDSC_DETAIL" ] || printf 'v' 
			) \
			--import-from-source --select-all-from-source \
			--print ''  -v \
			--build-all \
			--print '' \
	)
}

PrepareBuildDependencyIndex

