Require ListChangedSourceProjects

for PKG in $( ListChangedSourceProjects ) ; do
	CHECK_FILE="$MMDAPP/source/${PKG#$MMDAPP/source/}/build.number"
	if [ -f "$CHECK_FILE" ] ; then
		echo "$PKG: INCREMENT!"
	fi
done
