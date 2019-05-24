#!/bin/bash
# Execute shell commands in multiple directories grouped by tag

while read -p "fo.sh > " command ; do
  prefix=$(echo $command | grep -o '^@[0-9,]\+')
  selected=${prefix#@}
  selected=(${selected//,/ })
  command=$(echo $command | sed "s/^$prefix//")
  index=0

  while read dir; do
    index=$(( $index+1 ))
    if [[ "$selected" != "" ]] && [[ ! " ${selected[@]} " =~ " ${index} " ]]; then
      continue
    fi

    pushd $dir > /dev/null

    echo -e "\n______________________________________________________________________________"
    echo -e "@$index $(echo $dir | sed 's#.*/##' ) ($(echo $dir | sed 's#/.*##'))\n"

    /bin/bash -c "$command"

    popd > /dev/null
  done < ~/dirlist

  echo -e "\n=============================================================================="
done
