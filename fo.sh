#!/bin/bash
# Execute shell commands in multiple directories grouped by tag

PROGNAME=fo.sh

_parse_tag_arguments()
{
  if [[ $# == 0 ]]; then
    echo "$PROGNAME ! ERROR: No tags specified, exiting" >&2
    exit 1
  else
    while [ "$1" != "" ]; do
      echo ${1#@}
      shift
    done
  fi
}

_parse_dirlist_arguments()
{
  if [[ $# == 0 ]]; then
    if [[ -f ~/.$PROGNAME/MOST_RECENTLY_USED ]]; then
      echo "$PROGNAME ! WARNING: Using most recently used directory list" >&2
      readarray -t argument_dirs < ~/.$PROGNAME/MOST_RECENTLY_USED
    else
      echo "$PROGNAME ! ERROR: No directories specified, exiting" >&2
      exit 1
    fi
  else
    while [ "$1" != "" ]; do
      if [[ ${1:0:1} == "@" ]]; then
        readarray -t predefined_dir_list < ~/.$PROGNAME/${1#@}
        argument_dirs+=(${predefined_dir_list[@]})
      else
        argument_dirs+=($1)
      fi
      shift
    done
  fi
}

_normalize_paths()
{
  IFS=$'\n' unique_arguments=($(sort -u <<<"$*"))
  unset IFS

  for argument in "${unique_arguments[@]}"; do
    if [[ -d "$argument" ]]; then
      echo $(cd "$argument"; pwd)
    else
      echo "$PROGNAME ! SKIPPED: $argument: Not a directory" >&2
    fi
  done
}

_execute_command_in_directory()
{
    pushd $dir > /dev/null

    /bin/bash -c "(exit $prev_exit_code); $command"
    prev_exit_code=$?

    popd > /dev/null
}

run()
{
  argument_dirs=()
  _parse_dirlist_arguments $@

  target_dirs=($(_normalize_paths ${argument_dirs[@]}))

  mkdir -p ~/.$PROGNAME/
  printf "%s\n" "${target_dirs[@]}" > ~/.$PROGNAME/MOST_RECENTLY_USED

  while read -p "$PROGNAME > " command ; do
    command_prefix=$(echo $command | grep -o '^@[0-9,]\+')
    selected_indices=${command_prefix#@}
    selected_indices=(${selected_indices//,/ })
    command=$(echo $command | sed "s/^$command_prefix//")

    index=0
    prev_exit_code=0
    for dir in "${target_dirs[@]}"; do
      index=$(( $index+1 ))
      if [[ "$selected_indices" != "" ]] && [[ ! " ${selected_indices[@]} " =~ " ${index} " ]]; then
        continue
      fi

      echo -e "\n______________________________________________________________________________"
      echo -e "@$index $(echo $dir | sed 's#.*/##' ) ($(echo $dir | sed 's#/[^/]\+$##'))\n"

      _execute_command_in_directory
    done

    echo -e "\n=============================================================================="
  done
}

tag()
{
  target_tags=($(_parse_tag_arguments $@))
  if [[ $? != 0 ]]; then
    exit 1
  fi

  readarray -t dirs_from_stdin

  mkdir -p ~/.$PROGNAME/
  for tag in "${target_tags[@]}"; do
    readarray -t current_dirs_of_tag 2> /dev/null < ~/.$PROGNAME/$tag
    new_dirs_of_tag=$(_normalize_paths ${dirs_from_stdin[@]} ${current_dirs_of_tag[@]} | sort -u)
    printf "%s\n" "${new_dirs_of_tag[@]}" > ~/.$PROGNAME/$tag
  done
}

if [[ $# == 0 ]]; then
  echo "$PROGNAME ! ERROR: No command specified, exiting" >&2
  exit 1
else
  if ! ( declare -F | grep "^declare -f $1$" > /dev/null ); then
    echo "$PROGNAME ! ERROR: $1: No such command, exiting" >&2
    exit 1
  fi
  $@
fi
