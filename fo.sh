#!/bin/bash
# Execute shell commands in multiple directories grouped by tag

include_cd_exit_code=0

target_dirs=()
if [[ $# == 0 ]]; then
  echo "TODO: fo.sh ! WARNING: Using most recently used directory list"
else
  while [ "$1" != "" ]; do
    if [[ ${1:0:1} == "@" ]]; then
      readarray -t predefined_dir_list < ~/.fo.sh/${1#@}
      target_dirs+=(${predefined_dir_list[@]})
    else
      target_dirs+=($1)
    fi
    shift
  done
fi

while read -p "fo.sh > " command ; do
  prefix=$(echo $command | grep -o '^@[0-9,]\+')
  selected=${prefix#@}
  selected=(${selected//,/ })
  command=$(echo $command | sed "s/^$prefix//")
  index=0
  prev_exit_code=0

  for dir in "${target_dirs[@]}"; do
    index=$(( $index+1 ))
    if [[ "$selected" != "" ]] && [[ ! " ${selected[@]} " =~ " ${index} " ]]; then
      continue
    fi

    echo -e "\n______________________________________________________________________________"
    echo -e "@$index $(echo $dir | sed 's#.*/##' ) ($(echo $dir | sed 's#/.*##'))\n"

    pushd $dir > /dev/null
    pushd_exit_code=$?
    if [[ $pushd_exit_code != 0 ]]; then
      if [[ $include_cd_exit_code != 0 ]]; then
        prev_exit_code=$pushd_exit_code
      fi
      continue
    fi

    /bin/bash -c "(exit $prev_exit_code); $command"
    prev_exit_code=$?

    popd > /dev/null
  done

  echo -e "\n=============================================================================="
done
