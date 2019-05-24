#!/bin/bash
# Execute shell commands in multiple directories grouped by tag

include_cd_exit_code=0

argument_dirs=()
if [[ $# == 0 ]]; then
  echo "TODO: fo.sh ! WARNING: Using most recently used directory list"
  readarray -t argument_dirs < ~/.fo.sh/MOST_RECENTLY_USED
else
  while [ "$1" != "" ]; do
    if [[ ${1:0:1} == "@" ]]; then
      readarray -t predefined_dir_list < ~/.fo.sh/${1#@}
      argument_dirs+=(${predefined_dir_list[@]})
    else
      argument_dirs+=($1)
    fi
    shift
  done
fi

IFS=$'\n' sorted_argument_dirs=($(sort -u <<<"${argument_dirs[*]}"))
unset IFS

target_dirs=()
for dir in "${sorted_argument_dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    target_dirs+=($dir)
  else
    echo "fo.sh ! SKIPPED: $dir: Not a directory"
  fi
done

printf "%s\n" "${target_dirs[@]}" > ~/.fo.sh/MOST_RECENTLY_USED

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
