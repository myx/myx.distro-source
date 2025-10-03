
mkdir -p "$MDSC_OUTPUT/distro"

(
	Distro DistroSourceCommand \
		-v$( 
			[ -z "$MDSC_DETAIL" ] || printf 'v' 
		) \
		--import-from-source --select-all-from-source \
		--print ''  -v \
		--print-provides \
		--prepare-build \
		--print '' \
)

#			--prepare-build-roots --prepare-build-compile-index --prepare-build-distro-index \
#			--prepare-build-roots --prepare-build-compile-index --prepare-build-distro-index --prepare-build-fetch-missing \
