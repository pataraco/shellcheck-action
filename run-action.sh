#!/bin/bash

# finds all shell scripts/files and lints them with shellcheck

THIS_SCRIPT=$(basename "$0")
TMP_FILE=$(mktemp "/tmp/$THIS_SCRIPT.out.XXXXX") || exit 1
trap 'rm -f $TMP_FILE' EXIT
echo "beginning shell linting..."

# get the correct prefix for find perm
if find . -perm /777 -name junk &> /dev/null; then
   pp="/"
else
   pp="+"
fi

if [[ "$GITHUB_WORKSPACE" ]]; then
   cd "$GITHUB_WORKSPACE" || exit
fi

if [[ "$EXCLUDE_DIRS" ]]; then
   echo "excluding dir(s): ${EXCLUDE_DIRS// /, }"
else
   echo "not excluding any dirs"
fi

excludes=()
for dir in ${EXCLUDE_DIRS}; do
   # all find results start with './'
   [[ ${dir#./*} != "$dir" ]] || dir="./${dir}"
   excludes+=(! -path "$dir/*" -a)
done

echo "finding and linting all shell scripts/files via shellcheck..."
find \
   . "${excludes[@]}" \
   '(' \
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
   ')' \
   -exec bash -c '
      tmp_file=$1
      shift
      for f; do
         if shellcheck "$f"; then
            echo "[PASS]: shellcheck - successfully linted: $f"
         else
            err=$?
            echo "[FAIL]: shellcheck - found issues in: $f"
         fi
      done
      echo $err > $tmp_file
   ' _ "$TMP_FILE" {} + || exit
err1=$(cat "$TMP_FILE")

echo "finding and linting all files with shell shebangs via shellcheck..."
# shellcheck disable=SC2016
find . "${excludes[@]}" -type f ! -name '*.*' -perm ${pp}111 \
   -exec bash -c '
      tmp_file=$1
      shift
      for f; do
         head -n1 "$f" | grep -Eqs "^#! */[^ ]*/(env)?[ abkz]*sh" || continue
         if shellcheck "$f"; then
            echo "[PASS]: shellcheck - successfully linted: $f"
         else
            err=$?
            echo "[FAIL]: shellcheck - found issues in: $f"
         fi
      done
      echo $err > $tmp_file
   ' _ "$TMP_FILE" {} + || exit
err2=$(cat "$TMP_FILE")

echo "looking for subdirectories of bin directories that are not usable via PATH..."
if find . "${excludes[@]}" -path '*bin/*/*' -type f -perm ${pp}111 -print |
   grep .
then
   echo >&2 "[WARNING]: found subdirectories of bin directories that are not usable via PATH"
fi

echo "looking for programs in PATH that have a filename suffix"
if find . "${excludes[@]}" -path '*bin/*' -name '*.*' -type f -perm ${pp}111 -perm ${pp}444 -print |
   grep .
then
   echo >&2 "[WARNING]: found programs in PATH that have a filename suffix"
fi

echo "done"

err=${err1:=${err2:=0}}
exit "$err"
