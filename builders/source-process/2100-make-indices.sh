#!/bin/sh
###
### this script is included from builder
###

echo "Build: make indices start" >&2
Distro DistroSourceProcess --rebuild-output-index
