Require ListChangedSourceProjects

PrepareProjectHostInstallData(){
	local projectName="${1#$MMDAPP/source/}"
	[ -z "$projectName" ] && echo "⛔ ERROR: PrepareProjectHostInstallData: 'projectName' argument is required!" >&2 && return 1
	
	echo "$projectName: HOST INSTALL!"
}

ListChangedSourceProjects \
| while read -r projectName ; do
	if [ -d "$MDSC_SOURCE/$projectName/host/install" ] ; then
		PrepareProjectHostInstallData $projectName
	fi
done
