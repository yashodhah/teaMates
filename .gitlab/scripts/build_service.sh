#!/usr/bin/env bash
set -eu -o pipefail -E

DIR="${0%/*}"
# shellcheck source=../../other/utils.sh
source "${DIR}/../../other/utils.sh"

# shellcheck source=../common/common.sh
source "${DIR}/../common/common.sh"

# shellcheck source=./lib.sh
source "${DIR}/lib.sh"

function init_defaults() {
  set -eu -o pipefail -E

  : "${LOCAL_BUILD:="false"}"
  : "${DOCKER_BUILD_ARGS_PROXY:=""}"
  : "${BUILD_ARGS_EXTRA:=""}"
  : "${DOCKERFILE_PATH:=""}"
  : "${DOCKER_TARGET:=""}"
  : "${DOCKER_REGISTRY:="ecr"}"
  : "${DOCKER_REPOSITORY_NAME:=""}"
  : "${USE_LOG_LEVEL_ARG:=false}"
  : "${INJECT_TO_PROJECT_IMAGES:=true}"
  : "${ECR_ACCOUNT_IDS_EXTRA:=""}"
}

function check_env() {
  set -eu -o pipefail -E

  log_info_variable LOCAL_BUILD                               "${LOCAL_BUILD}"
  log_info_variable SERVICE_NAME                              "${SERVICE_NAME}"
  log_info_variable CI_PROJECT_NAME                           "${CI_PROJECT_NAME}"
  log_info_variable CI_PIPELINE_ID                            "${CI_PIPELINE_ID}"
  log_info_variable CI_COMMIT_REF_SLUG                        "${CI_COMMIT_REF_SLUG}"

  log_info_variable DOCKER_BUILD_ARGS_PROXY                   "${DOCKER_BUILD_ARGS_PROXY}"
  log_info_variable BUILD_ARGS_EXTRA                          "${BUILD_ARGS_EXTRA}"
  log_info_variable DOCKERFILE_PATH                           "${DOCKERFILE_PATH}"
  log_info_variable DOCKER_TARGET                             "${DOCKER_TARGET}"
  log_info_variable DOCKER_REGISTRY                           "${DOCKER_REGISTRY}"
  log_info_variable DOCKER_REPOSITORY_NAME                    "${DOCKER_REPOSITORY_NAME}"
  log_info_variable USE_LOG_LEVEL_ARG                         "${USE_LOG_LEVEL_ARG}"
  log_info_variable INJECT_TO_PROJECT_IMAGES                  "${INJECT_TO_PROJECT_IMAGES}"
  log_info_variable ECR_REPOSITORY_SUFFIX                     "${ECR_REPOSITORY_SUFFIX}"
  log_info_variable ECR_ACCOUNT_IDS_EXTRA                     "${ECR_ACCOUNT_IDS_EXTRA}"
  log_info_variable AWS_EU_REGION                             "${AWS_EU_REGION}"
  log_info_variable AWS_EU_REGION_BACKUP                      "${AWS_EU_REGION_BACKUP}"
  log_info_variable AWS_US_REGION                             "${AWS_US_REGION}"
  log_info_variable AWS_US_REGION_BACKUP                      "${AWS_US_REGION_BACKUP}"
  log_info_variable PUSH_TO                                   "${PUSH_TO}"

  # The "eu" destination is mandatory, as all images are built against "eu" to access any required base images,
  # and also push to "eu" (i.e. eu-west-1 in Shared EU AWS Account) is used for ECR Vulnerability Scan.
  if ! echo " ${PUSH_TO} " | tr '\n' ' ' | grep -q -E '[[:space:]]+eu[[:space:]]+'; then
    log_this ERROR "PUSH_TO variable must always contain 'eu' destination."
    exit 1
  fi

}

function get_push_to_region() {
  set -eu -o pipefail -E

  local destination="$1"

  declare -A regions=(
    ["eu"]="${AWS_EU_REGION}"
    ["eu_backup"]="${AWS_EU_REGION_BACKUP}"
    ["us"]="${AWS_US_REGION}"
    ["us_backup"]="${AWS_US_REGION_BACKUP}"
  )

  echo "${regions["${destination}"]}"
}

function get_push_to_account_id() {
  set -eu -o pipefail -E

  local destination="$1"

  declare -A regions=(
    ["eu"]="${SHARED_EU_ACCOUNT_ID}"
    ["eu_backup"]="${SHARED_EU_ACCOUNT_ID}"
    ["us"]="${SHARED_US_ACCOUNT_ID}"
    ["us_backup"]="${SHARED_US_ACCOUNT_ID}"
  )

  echo "${regions["${destination}"]}"
}

function push_to() {
  set -eu -o pipefail -E

  local destination="$1"

  local destination_region
  local destination_account_id

  destination_region="$(get_push_to_region "${destination}")"
  destination_account_id="$(get_push_to_account_id "${destination}")"

  log_this INFO "Pushing image to: ${destination}"

  # Push official version of the image, generate reports for Retag-on-Release, and perform Vulnerability Scans.
  shift # Remove first parameter from "$@" as is not needed in publish_service_image
  publish_service_image "${destination_region}" "${destination_account_id}" ".images/" "$@"

  # Only when releasing to "snapshot" repositories:
  # Publish cached version of the image for reuse on subsequent builds.
  if [[ "${ECR_REPOSITORY_SUFFIX}" == "snapshot" ]]; then
    publish_service_image_version_tag "cached" "${destination_region}" "${destination_account_id}"
  fi
}

init_defaults
configure_docker_dind
configure_docker_build
check_env

# Note: Build is always against repositories in main EU region.
build_service_image "${AWS_EU_REGION}" "${SHARED_EU_ACCOUNT_ID}"

if [[ "${LOCAL_BUILD}" != "true" ]]; then

  # The "eu" destination is always used because that's where we run ECR Vulnerability Scans.
  push_to "eu" "amazon-ecr-scan"

  # Push to all requested destinations other than "eu", this time just a simple push
  for destination in $(echo " ${PUSH_TO} " | tr '\n' ' ' | sed -E 's/\seu\s/ /'); do
    push_to "${destination}"
  done

  # Finally, remove the image using its `build_tag`. This should free some space on Gitlab Runners.
  remove_local_service_image

else
  log_this INFO "Image built locally: $(get_build_tag "${SERVICE_NAME}")"
fi
