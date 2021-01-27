
# Require PrepareRepositorySyncToCached
Require DistroSourceCommand

PrepareBuildDependencyIndex(){
	mkdir -p "$MMDAPP/output/distro"
	
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
		local javaClassPath="${javaClassPath:-"-classpath \""} $projectClasses"
		local javaSourcePath="${javaSourcePath:-"-sourcepath \""} $projectSources"
	done
	[ -z "$javaClassPath" ] || local javaClassPath="$javaClassPath\""
	[ -z "$javaSourcePath" ] || local javaSourcePath="$javaSourcePath\""

	for projectName in $projectList ; do
		local projectClasses="$MMDAPP/output/cached/$projectName/java"
		local projectSources="$MMDAPP/cached/sources/$projectName/java"
		local projectQueue="$( find "$projectSources" -type f -name '*.java' )"
		if [ ! -z "${projectQueue:0:1}" ] ; then
			local checkSourceFile checkClassFile
			local sourceFilesQueue="$( \
				echo "$projectQueue" \
				| while read -r checkSourceFile ; do
					checkClassFile="$( echo "$projectClasses${checkSourceFile%'$projectSources'}" | sed 's:\.java$:\.class:g' )"
					if [ ! -f "$checkClassFile" ] || [ "$checkSourceFile" -nt "$checkClassFile" ] ; then
						printf "$checkSourceFile "
					fi
				done
			)" 
			if [ ! -z "$sourceFilesQueue" ] ; then
				echo "Compiling: $projectName..." >&2
				eval "javac -nowarn -d '$projectClasses' $javaClassPath $javaSourcePath -g -parameters $sourceFilesQueue 2> /dev/null || true"
				echo "Done compiling: $projectName." >&2
			fi
		fi
	done

	echo "Done making java distro classes." >&2
	##
	## /end
	##
	
	
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

