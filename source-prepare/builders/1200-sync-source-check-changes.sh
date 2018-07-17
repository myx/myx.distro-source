Require ListAllRepositories
Require SyncSourceRepositoryToCached

PrepareSyncSourceCheckChanges(){
	for REPO in $( ListAllRepositories ) ; do
		Async -2 SyncSourceRepositoryToCached "$REPO"
	done
	wait
}

PrepareSyncSourceCheckChanges

#			--prepare-build-roots --prepare-build-cached-index --prepare-build-distro-index \
#			--prepare-build-roots --prepare-build-compile-index --prepare-build-distro-index --prepare-build-fetch-missing \
