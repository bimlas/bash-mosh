#!/bin/bash
# Execute shell commands in multiple directories grouped by tags

PROGNAME=fo.sh

run()
{
  target_dirs=$(_convert_args_to_lines "$@" | _get_target_dirs)
  if [[ "$target_dirs" == "" ]]; then
    _echo_to_stderr "ERROR: No directories specified, exiting"
    exit 1
  fi

  echo "$target_dirs" | _set_dirs_of_tag MOST_RECENTLY_USED

  while read -p "$PROGNAME > " command ; do
    previous_exit_code=0
    command_prefix=$(echo "$command" | grep -o "^@[0-9,]\+")
    selected_indices=$(echo "${command_prefix#@}" | sed "s/,/\n/g")
    command=$(echo "$command" | sed "s/^$command_prefix//")

    index=0
    prev_exit_code=0
    while read dir; do
      index=$(("$index"+1))
      if ! ( echo "$selected_indices" | _is_not_excluded "$index" ); then
        continue
      fi

      _echo_step_separator "$index" "$dir"

      (/bin/bash -c "cd '$dir'; (exit $previous_exit_code); $command")
      previous_exit_code=$?
    done <<< "$target_dirs"

    _echo_run_separator
  done
}

tag()
{
  if [[ $# == 0 ]]; then
    _echo_to_stderr "ERROR: No tags specified, exiting"
    exit 1
  fi

  dirs_from_stdin=$(cat)
  for tag in $(_convert_args_to_lines "$@" | _strip_tag_prefix); do
    echo "$dirs_from_stdin" | _extend_dirs_of_tag "$tag"
  done
}

_get_target_dirs()
{
  tag_and_dir_list=$(cat)
  if [[ "$tag_and_dir_list" != "" ]]; then
    echo "$tag_and_dir_list" | _convert_tag_and_dir_list_to_dirs | _normaize_dir_paths
  elif [[ -f ~/."$PROGNAME"/MOST_RECENTLY_USED ]]; then
    _echo_to_stderr "WARNING: Using most recently used directory list"
    _get_dirs_of_tag MOST_RECENTLY_USED
  fi
}

_convert_tag_and_dir_list_to_dirs()
{
  while read tag_or_dir; do
    if [[ "${tag_or_dir:0:1}" == "@" ]]; then
      _get_dirs_of_tag "$tag_or_dir"
    else
      echo "$tag_or_dir"
    fi
  done
}

_normaize_dir_paths()
{
  while read dir_path; do
    if [[ "$dir_path" == "" ]]; then
      continue
    fi
    if [[ -d "$dir_path" ]]; then
      (cd "$dir_path"; pwd)
    else
      _echo_to_stderr "SKIPPED: $dir_path: Not a directory"
    fi
  done | sort -u
}

_get_dirs_of_tag()
{
  tag_filename=$(echo "$1" | _strip_tag_prefix)
  if [[ ! -f ~/."$PROGNAME"/"$tag_filename" ]]; then
    _echo_to_stderr "SKIPPED: $1: Tag not exists"
  else
    cat ~/."$PROGNAME"/"$tag_filename" 2> /dev/null
  fi
}

_set_dirs_of_tag()
{
  mkdir -p ~/."$PROGNAME"/
  if ! ( cat 2> /dev/null > ~/."$PROGNAME"/$(echo "$1" | _strip_tag_prefix) ); then
    _echo_to_stderr "ERROR: $1: Cannot set tag"
  fi
}

_extend_dirs_of_tag()
{
  new_dirs_of_tag=$(cat)
  current_dirs_of_tag=$(_get_dirs_of_tag "$1" 2> /dev/null)
  echo -e "$new_dirs_of_tag\n$current_dirs_of_tag" | _normaize_dir_paths | _set_dirs_of_tag "$tag"
}

_strip_tag_prefix()
{
  sed "s/^@//"
}

_convert_args_to_lines()
{
  printf "%s\n" "$@"
}

_is_not_excluded()
{
  selected_indices=$(cat)
  [[ "$selected_indices" == "" ]] || ( echo "$selected_indices" | grep "^$1$" )
}

_is_command_defined()
{
  declare -F | grep "^declare -f $1$" > /dev/null
}

_echo_step_separator()
{
  echo -e "\n______________________________________________________________________________"
  echo -e "@$1 $(echo $2 | sed 's#.*/##' ) ($(echo $2 | sed 's#/[^/]\+$##'))\n"
}

_echo_run_separator()
{
  echo -e "\n=============================================================================="
}

_echo_to_stderr()
{
  echo "$PROGNAME ! $*" >&2
}

if [[ $# == 0 ]]; then
  _echo_to_stderr "ERROR: No command specified, exiting"
  exit 1
else
  if ! ( _is_command_defined "$1" ); then
    _echo_to_stderr "ERROR: $1: No such command, exiting"
    exit 1
  fi
  "$@"
fi
