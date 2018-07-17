Require ListChangedSourceProjects

for PKG in $( ListChangedSourceProjects ) ; do
	CHECK_DIR="$MDSC_SOURCE/$PKG/host/install"
	if [ -d "$CHECK_DIR" ] ; then
		echo "$PKG: HOST INSTALL!"
	fi
done
