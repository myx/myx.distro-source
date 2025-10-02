
mkdir -p "$MMDAPP/output/distro"

( \
	Distro DistroSourceCommand \
		-v \
		--output-root "$MMDAPP/output" \
		--source-root "$MMDAPP/.local/source-cache/sources" \
		--cached-root "$MMDAPP/output/cached" \
		--import-from-source --select-all-from-source \
		--print ''  -v \
		--print-provides \
		--prepare-build \
		--print '' \
)

#			--prepare-build-roots --prepare-build-compile-index --prepare-build-distro-index \
#			--prepare-build-roots --prepare-build-compile-index --prepare-build-distro-index --prepare-build-fetch-missing \
