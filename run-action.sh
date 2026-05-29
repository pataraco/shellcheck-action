#!/bin/bash
#
# Find every shell script/file in the repository and lint it with ShellCheck.
#
# Inputs (env vars, set by action.yml from the action's `with:` inputs):
#   EXCLUDE_DIRS      space-separated dir names/paths to skip (e.g. ".github vendor")
#   SEVERITY          minimum severity to report & fail on: error|warning|info|style
#                     (default: style — report everything)
#   EXTERNAL_SOURCES  "true" to follow sourced files (shellcheck -x)

set -uo pipefail

echo "beginning shell linting..."
shellcheck --version
echo

# Move into the checked-out repository.
if [[ "${GITHUB_WORKSPACE:-}" ]]; then
   cd "$GITHUB_WORKSPACE" || exit 1
fi

# --- Build shellcheck options from inputs -----------------------------------
sc_opts=()
[[ -n "${SEVERITY:-}" ]] && sc_opts+=("--severity=${SEVERITY}")
[[ "${EXTERNAL_SOURCES:-}" == "true" ]] && sc_opts+=("-x")

# --- Build find exclusions from EXCLUDE_DIRS --------------------------------
if [[ "${EXCLUDE_DIRS:-}" ]]; then
   echo "excluding dir(s): ${EXCLUDE_DIRS// /, }"
else
   echo "not excluding any dirs"
fi
excludes=()
# Word-splitting of EXCLUDE_DIRS into separate dirs is intentional.
# shellcheck disable=SC2086
for dir in ${EXCLUDE_DIRS:-}; do
   # find results start with './'; a leading './' means a specific path,
   # otherwise match the dir name anywhere in the tree.
   [[ ${dir%%[^./]*} != "./" ]] && dir="*/${dir}"
   excludes+=(! -path "$dir/*" -a)
done

# --- Collect target files ---------------------------------------------------
declare -a files=()

# 1) files named/pathed like shell files
while IFS= read -r -d '' f; do
   files+=("$f")
done < <(
   find . "${excludes[@]}" -type f '(' \
            -name '*.bash'       \
         -o -path '*/.bash*'     \
         -o -path '*/bash*'      \
         -o -name '*.ksh'        \
         -o -name 'ksh*'         \
         -o -path '*/.ksh*'      \
         -o -path '*/ksh*'       \
         -o -name 'suid_profile' \
         -o -name '*.zsh'        \
         -o -name '.zlogin*'     \
         -o -name 'zlogin*'      \
         -o -name '.zlogout*'    \
         -o -name 'zlogout*'     \
         -o -name '.zprofile*'   \
         -o -name 'zprofile*'    \
         -o -path '*/.zsh*'      \
         -o -path '*/zsh*'       \
         -o -name '*.sh'         \
         -o -path '*/.profile*'  \
         -o -path '*/profile*'   \
         -o -path '*/.shlib*'    \
         -o -path '*/shlib*'     \
      ')' -print0
)

# 2) extension-less executables whose shebang names a shell
while IFS= read -r -d '' f; do
   head -n1 "$f" | grep -Eqs "^#! */[^ ]*/(env)?[ abkz]*sh" && files+=("$f")
done < <(find . "${excludes[@]}" -type f ! -name '*.*' -perm -111 -print0)

# de-duplicate (a file can match both passes)
if [[ ${#files[@]} -gt 0 ]]; then
   mapfile -t files < <(printf '%s\n' "${files[@]}" | sort -u)
fi

if [[ ${#files[@]} -eq 0 ]]; then
   echo "no shell files found to lint"
   exit 0
fi

echo "linting ${#files[@]} file(s): shellcheck ${sc_opts[*]}"
echo

# --- Run shellcheck, print results, and emit GitHub annotations -------------
# gcc format is one finding per line: file:line:col: severity: message [SCxxxx]
output=$(shellcheck "${sc_opts[@]}" --format=gcc "${files[@]}" 2>&1)
rc=$?

if [[ -n "$output" ]]; then
   printf '%s\n' "$output"
   # Convert each finding into a GitHub annotation so it shows on the PR diff.
   printf '%s\n' "$output" | awk -F: '
      NF >= 4 {
         file=$1; line=$2; col=$3
         rest=$0; sub(/^[^:]*:[^:]*:[^:]*: */, "", rest)   # strip "file:line:col: "
         level=rest; sub(/:.*/, "", level)                  # severity word
         msg=rest;  sub(/^[a-z]+: */, "", msg)              # message text
         gh=(level=="error") ? "error" : (level=="warning") ? "warning" : "notice"
         printf "::%s file=%s,line=%s,col=%s::%s\n", gh, file, line, col, msg
      }'
fi

# --- Extra sanity checks (non-failing warnings) -----------------------------
if find . "${excludes[@]}" -path '*bin/*/*' -type f -perm -111 -print | grep -q .; then
   echo >&2 "[WARNING]: found subdirectories of bin directories not usable via PATH"
fi
if find . "${excludes[@]}" -path '*bin/*' -name '*.*' -type f -perm -111 -perm -444 -print | grep -q .; then
   echo >&2 "[WARNING]: found programs in PATH that have a filename suffix"
fi

if [[ $rc -eq 0 ]]; then
   echo "[PASS]: all ${#files[@]} shell file(s) passed shellcheck"
else
   echo "[FAIL]: shellcheck reported issues"
fi
exit "$rc"
