###
### this script is included from builder
###

echo "Build: make commands index start" >&2

### stage order is load-bearing: the declares query below reads the cached index,
### so this must run after 1100-make-indices.sh
### not under system-index/ or source-cache/: both are wiped by the ingest
INDEX_COMMANDS="$MMDAPP/.local/distro-commands.txt"

mkdir -p "${INDEX_COMMANDS%/*}"

Distro ListDistroDeclares --all-filter-and-cut custom-commands-path \
| while read -r projectName commandsPath ; do
	scriptsDir="$MMDAPP/source/$projectName/${commandsPath#/}"
	[ -d "$scriptsDir" ] || continue
	for commandFile in "$scriptsDir"/*.fn.sh ; do
		[ -x "$commandFile" ] || continue
		commandName="${commandFile##*/}"
		printf '%s %s %s\n' "$projectName" "${commandName%.fn.sh}" "$scriptsDir"
	done
done > "$INDEX_COMMANDS.$$.tmp"

mv -f "$INDEX_COMMANDS.$$.tmp" "$INDEX_COMMANDS"

### the derived line the consoles read on every call instead of walking the index: the distinct sh-scripts folders, colon-joined,
### written beside the index with it (myx.distro-.local/sh-lib/console-.local-path.include, myx.distro-system SystemConsole.include)
awk '!seenScriptsDir[$3]++ && $3 != "" { printf "%s%s", sep, $3 ; sep = ":" } END { print "" }' "$INDEX_COMMANDS" > "${INDEX_COMMANDS%/*}/distro-command-path.txt.$$.tmp" \
	&& mv -f "${INDEX_COMMANDS%/*}/distro-command-path.txt.$$.tmp" "${INDEX_COMMANDS%/*}/distro-command-path.txt"
