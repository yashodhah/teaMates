#!/usr/bin/env bash

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
declare -A colours=([DEFAULT]='\e[39m' [LIGHT_RED]='\e[91m' [LIGHT_YELLOW]='\e[93m' [LIGHT_GREEN]='\e[92m' [BLUE]='\e[34m')
declare -A colour_levels=([DEBUG]='DEFAULT' [INFO]='LIGHT_GREEN' [WARN]='LIGHT_YELLOW' [ERROR]='LIGHT_RED')
: "${LOG_LEVEL:=INFO}"

########################################################################################################################
# This function can be used to log
# Example Usage:
# 1| LOG_LEVEL=DEBUG # Available: DEBUG, INFO, WARN, ERROR | Default is INFO
# 2| source .cicd_scripts/other/utils.sh
# 3| log_this INFO "my sample message"
# 4| log_this INFO "my sample message" LIGHT_RED
# Result:
# 2020-05-06 18:29:58.455 INFO - my sample message
# 2020-05-06 18:29:58.455 INFO - my sample message # imagine "my sample message" is coloured :)
########################################################################################################################
log_this() {
    local log_priority=$1
    local log_message=$2

    local default_log_colour=${colours[DEFAULT]}

    local level_colour_name=${colour_levels[$log_priority]}
    local level_colour=${colours[$level_colour_name]}

    local message_colour_name=${3:-DEFAULT}
    local message_colour=${colours[$message_colour_name]}

    local date_time=$(date "+%Y-%m-%d %H:%M:%S.%3N")

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$LOG_LEVEL]} )) && return 0

    printf "${default_log_colour}%s ${level_colour}%s${default_log_colour} - ${message_colour}%s${default_log_colour}\n" "${date_time}" "${log_priority}" "${log_message}" >&2
}

_pad_printf() {
  local pad_length=60
  local string1=$1
  local string2=$2
  local pad=$(printf '%0.1s' " "{1..60})
  local pad_calculated=$((pad_length - ${#string1} ))
  printf '%s' "$string1"
  printf '%*.*s' 0 $pad_calculated "$pad"
  printf '%s\n' "$string2"
}

########################################################################################################################
# This function can be used to log variable
# Example Usage:
# 1| log_debug_variable AWS_REGION "$AWS_REGION"
# Result:
# 2020-05-06 18:29:58.457 DEBUG - AWS_REGION                                       #eu-west-1#
########################################################################################################################
log_debug_variable() {
  local name=$1
  local value=$2
  log_this DEBUG "$(_pad_printf "${name}" "#${value}#")"
}

log_info_variable() {
  local name=$1
  local value=$2
  log_this INFO "$(_pad_printf "${name}" "#${value}#")"
}

########################################################################################################################
# This function can be used to validate if directory exists
########################################################################################################################
validate_dir_exists() {
  local path=$1
  if [ -d "$path" ]; then
    log_this DEBUG "Directory ${path} exists"
  else
    log_this ERROR "Directory ${path} not exists! Exiting!"
    exit 1
  fi
}

########################################################################################################################
# This function can be used to validate if file exists
########################################################################################################################
validate_file_exists() {
  local path=$1
  if [ -f "$path" ]; then
    log_this DEBUG "File ${path} exists"
  else
    log_this ERROR "File ${path} not exists! Exiting!"
    exit 1
  fi
}


########################################################################################################################
# This function can be used to validate if file exists and it's not empty
########################################################################################################################
validate_file_exists_and_not_empty() {
  local path=$1
  validate_file_exists "${path}"
  if [ -s "$path" ]; then
    local lines=$(wc -l "${path}" | cut -d' ' -f1)
    local chars=$(wc -c "${path}" | cut -d' ' -f1)
    log_this DEBUG "File ${path} is not empty. It have ${lines} lines and ${chars} chars"
  else
    log_this ERROR "File ${path} is empty! Exiting!"
    exit 1
  fi
}

########################################################################################################################
# This function can be used to validate semantic version string
########################################################################################################################
validate_version_string() {
  local version=$1
  rx='^([0-9]+\.){0,2}(\*|[0-9]+)$'
  if [[ $version =~ $rx ]]; then
    log_this INFO "Version '${version}' is valid"
  else
    log_this ERROR "Unable to validate version string: '{$version}'"
    exit 1
  fi
}

########################################################################################################################
# This function can be used to scan subdir and get dirs as array.
# Example Usage:
# 1| local unit_dirs
# 2| local unit_integration_dirs
# 3| get_subdirs_as_array ".images" images_dir
# 4| for service_name in "${images_dir[@]}" ; do
# 5|   echo "service: ${service_name}"
# 6| done
# Result:
# 1| service: template
# 2| service: webapp1
########################################################################################################################
get_subdirs_as_array() {
  local original_path=$(pwd)
  log_debug_variable original_path "$original_path"

  local scan_dir=$1
  local -n array_name=$2 # use nameref for indirection
  local ignore_dirs=${3:-""}

  log_this DEBUG "Scanning dirs inside \"${scan_dir}\", ignoring dirs: \"${ignore_dirs}\""

  cd "${scan_dir}"
  local ls_result=$(ls -d */)

  local dirs=""
  for dir in ${ls_result} ; do
    dir="${dir%?}"
    log_this DEBUG "dir: ${dir}"
    dirs="${dirs} ${dir}"
  done

  array_name=($dirs)
  cd "${original_path}"
}

########################################################################################################################
# This function is used to execute other bash script if they exist
# Example Usage:
# 1| execute_script_if_exists "${POST_TF_APPLY_SCRIPT}" [any] [additional] [parameter] ...
########################################################################################################################
execute_script_if_exists() {
  local script_path=${1:-""}
  shift

  log_this DEBUG "script_path: ${script_path}"

  if [ -f "${script_path}" ]; then
    log_this INFO "Executing: ${script_path}"
    validate_file_exists "${script_path}"
    bash "${script_path}" "$@"
    local status=$?
    log_this DEBUG "status: ${status}"
  else
    log_this INFO "${script_path} does not exist. Nothing to execute."
  fi
}

########################################################################################################################
# This function is used to check if root user is executing current function
# Example Usage:
# 1| if is_user_root; then
# 2|   echo 'You are the almighty root!'
# 3|   exit 0 # implicit, here it serves the purpose to be explicit for the reader
# 4| else
# 5|   echo 'You are just an ordinary user.' >&2
# 6|   exit 1
# 7| fi
########################################################################################################################
is_user_root () { [ ${EUID:-$(id -u)} -eq 0 ]; }
