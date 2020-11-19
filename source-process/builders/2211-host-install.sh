Require ListChangedSourceProjects

PrepareProjectHostInstallData(){
	local projectName="${1#$MMDAPP/source/}"
	[ -z "$projectName" ] && echo "PrepareProjectHostInstallData: 'projectName' argument is required!" >&2 && return 1
	
	echo "$projectName: HOST INSTALL!"
}

for projectName in $( ListChangedSourceProjects ) ; do
	CHECK_DIR="$MDSC_SOURCE/$projectName/host/install"
	if [ -d "$CHECK_DIR" ] ; then
		PrepareProjectHostInstallData $projectName
	fi
done
