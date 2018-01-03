#!/bin/sh

help() {
  echo "Usage: $0 -d <repo-root-folder> -v <new-version>"
}

## I. Check parameter
repo_root=""
new_version=""
while getopts 'd:v:' flag; do
  case "${flag}" in
    d)
      repo_root=${OPTARG}
      ;;
    v)
      new_version=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$repo_root" == "" ] || [ "$new_version" == "" ]; then
  help
  exit 1
fi

document_folder=$repo_root/Documentation
version_config=$repo_root/Config/Version.xcconfig

sed -i '' 's/\(VERSION_STRING[[:space:]]=[[:space:]]\).*/\1'$new_version'/g' $version_config

files=`find $document_folder -name '.jazzy.yaml' -type f`
for file in $files
do
  sed -i '' 's/\(module_version:[[:space:]]\).*/\1'$new_version'/g' $file
done
