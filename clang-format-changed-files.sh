#!/usr/bin/env bash

# This script runs clang_format on all .h, .m, and .mm files that have changes from develop branch.
# Before running this, ensure that your local develop branch is up to date.
upstream=$(git remote -v | grep "Microsoft/" | awk '{print $1}' | uniq)
git fetch $upstream
i=0
for modified_file in $(git diff $upstream/develop --diff-filter=ACMR --name-only -- *.h *.m *.mm)
do
  if [[ $modified_file != *"Vendor/"* ]]
  then
    clang-format -i -style=file $modified_file
    exit_code=$?
    if [ $exit_code -ne 0 ]
    then
      echo "Failed to format file: "$modified_file
    else
      ((i++))
    fi
  fi
done
echo "Formatted "$i" file(s)."
