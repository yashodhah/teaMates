declare -A COMMON_ECR_PREFIXES=(
  ["275592048886"]="shared-eu"
  ["368768292373"]="shared-us"
)

REPORT_FILE_NAME="docker_data_service.json"

function _get_docker_registry() {
  set -eu -o pipefail -E

  local region="$1"
  local account_id="$2"

  echo "${account_id}.dkr.ecr.${region}.amazonaws.com"
}

function _get_docker_repository_name() {
  # Generates an ECR Registry name depending on the DOCKER_REPOSITORY_NAME override or using naming convention
  # applied in Generics Infrastructure, where all ECR repositories should be created. This is required
  # because - due to said naming convention - our ECR repositories are still prefixed with environment
  # name (shared-eu/us) and that part needs to be prepended regardless of the override.
  set -eu -o pipefail -E

  local account_id="$1"

  # shellcheck disable=SC2153
  if [[ "${DOCKER_REPOSITORY_NAME}" == "" ]]; then
    local clean_service_name="${SERVICE_NAME//_/-}"
    name="${COMMON_ECR_PREFIXES[${account_id}]}/services/${CI_PROJECT_NAME}/${clean_service_name}/${ECR_REPOSITORY_SUFFIX}"
  else
    name="${COMMON_ECR_PREFIXES[${account_id}]}/${DOCKER_REPOSITORY_NAME}"
  fi

  echo "${name}"
}

function _get_push_tag() {
  # Returns a full docker tag including repository name, image name and its tag.
  # To be used with `docker push` of to identify potentially existing/cached images for pull.
  set -eu -o pipefail -E

  local version_flavour="$1"
  local region="$2"
  local account_id="$3"

  local docker_registry
  local docker_repository_name
  local version

  docker_registry="$(_get_docker_registry "${region}" "${account_id}")"
  docker_repository_name="$(_get_docker_repository_name "${account_id}")"
  version="$(get_project_version "${version_flavour}")"

  local push_tag="${docker_registry}/${docker_repository_name}:${version}"
  echo "${push_tag}"
}

function _get_report_file_path() {
  set -eu -o pipefail -E

  local report_files_dir="$1"
  local region="$2"
  local account_id="$3"
  local repository_name
  local report_file_path

  repository_name="$(_get_docker_repository_name "${account_id}")"
  report_file_path="${report_files_dir}/${repository_name}/${region}/${account_id}/${REPORT_FILE_NAME}"
  echo "${report_file_path}"
}

function build_service_image() {
  set -eu -o pipefail -E

  local region="$1"
  local account_id="$2"

  local docker_target
  local dockerfile_path
  local build_tag

  docker_target="$(get_docker_target "${SERVICE_NAME}")"
  dockerfile_path="$(get_dockerfile_path "${SERVICE_NAME}")"
  build_tag="$(get_build_tag "${SERVICE_NAME}")"

  docker_login "ecr" "${region}" "${account_id} ${ECR_ACCOUNT_IDS_EXTRA:-""}"

  log_this INFO "Building image: ${build_tag} using: ${dockerfile_path}"

  BUILD_ARGS_EXTRA="${BUILD_ARGS_EXTRA} --no-cache"
  # https://docs.gitlab.com/ee/user/packages/pypi_repository/#authenticate-with-a-ci-job-token
  BUILD_ARGS_EXTRA="${BUILD_ARGS_EXTRA} --build-arg POETRY_HTTP_BASIC_PRIVATE_GITLAB_REPO_USERNAME=${POETRY_HTTP_BASIC_PRIVATE_GITLAB_REPO_USERNAME}"
  BUILD_ARGS_EXTRA="${BUILD_ARGS_EXTRA} --build-arg POETRY_HTTP_BASIC_PRIVATE_GITLAB_REPO_PASSWORD=${POETRY_HTTP_BASIC_PRIVATE_GITLAB_REPO_PASSWORD}"

  log_info_variable DOCKER_BUILD_ARGS_PROXY                   "${DOCKER_BUILD_ARGS_PROXY}"
  log_info_variable BUILD_ARGS_EXTRA                          "${BUILD_ARGS_EXTRA}"

  # shellcheck disable=SC2086
  docker build -t "${build_tag}" \
    ${DOCKER_BUILD_ARGS_PROXY} ${BUILD_ARGS_EXTRA} \
    --target "${docker_target}" \
    --file "${dockerfile_path}" .

}

function _run_vulnerability_scan_with_ecr() {
  set -eu -o pipefail -E

  local report_file_path="$1"

  log_debug_variable DISABLE_ACTIVITY_vulnerability_scan_ecr "${DISABLE_ACTIVITY_vulnerability_scan_ecr:-''}"

  if [[ "${DISABLE_ACTIVITY_vulnerability_scan_ecr:-''}" == "true" ]]; then
    log_this WARN "Activity vulnerability_scan_ecr is disabled. To enable unset DISABLE_ACTIVITY_vulnerability_scan_ecr."
  else
    # shellcheck disable=SC1090
    . "${PROJECT_VENV_DIR}/bin/activate"
    python3 .cicd_scripts/security/vulnerability_scan/ecr/main.py \
      --image-data-path "${report_file_path}" \
      --whitelist-path "${VULN_WHITELIST_PATH}" \
      --reports-dir "${VULN_SCAN_REPORTS_DIR}"

  fi

}

function _generate_report() {
  set -eu -o pipefail -E

  local region="$1"
  local account_id="$2"
  local report_file_path="$3"

  local repository_name
  local image_tag
  local image_digest

  repository_name="$(_get_docker_repository_name "${account_id}")"
  image_tag="$(get_project_version "incremental")"
  image_digest="$(aws ecr describe-images                    \
                      --region "${region}"                   \
                      --registry-id "${account_id}"          \
                      --repository-name "${repository_name}" \
                      --image-ids "imageTag=${image_tag}"    \
                  | jq -r '.imageDetails[0].imageDigest')"

  mkdir -p "$(dirname "${report_file_path}")"

  # shellcheck disable=SC2016
  local report_template='{
        "registry_id":     $registry_id,
        "region":          $region,
        "repository_name": $repository_name,
        "image_tag":       $image_tag,
        "image_digest":    $image_digest
    }'

  jq -n "${report_template}" \
    --arg "registry_id" "${account_id}" \
    --arg "region" "${region}" \
    --arg "repository_name" "${repository_name}" \
    --arg "image_tag" "${image_tag}" \
    --arg "image_digest" "${image_digest}" \
    >"${report_file_path}"

}

function publish_service_image_version_tag() {
  set -eu -o pipefail -E

  # See: common/common.sh :: get_project_version()
  local version_flavour="$1"

  local region="$2"
  local account_id="$3"

  local build_tag
  local push_tag

  build_tag="$(get_build_tag "${SERVICE_NAME}")"
  push_tag="$(_get_push_tag "${version_flavour}" "${region}" "${account_id}")"

  docker_login "ecr" "${region}" "${account_id}"

  log_this INFO "Tagging build-image as: ${push_tag}"
  docker tag "${build_tag}" "${push_tag}"

  log_this INFO "Pushing image ${push_tag} to remote repository"
  docker push "${push_tag}"

  # Immediately remove that tag. This will keep the image locally because the `build_tag` will still exist,
  # but thanks to this, we'll be able to remove the build tag to remove the image completely and free disk space.
  docker rmi -f "${push_tag}" 2>/dev/null || true

}

function publish_service_image() {
  set -eu -o pipefail -E

  local region="$1"
  local account_id="$2"
  local report_files_dir="$3"
  local requested_vulnerability_scans="${4:-""}"
  local report_file_path

  publish_service_image_version_tag "incremental" "${region}" "${account_id}"

  # Generate reports and run scans for "incremental" (i.e. official) versions only.
  report_file_path="$(_get_report_file_path "${report_files_dir}" "${region}" "${account_id}")"

  _generate_report "${region}" "${account_id}" "${report_file_path}"

  if [[ "${requested_vulnerability_scans}" == *"amazon-ecr-scan"* ]]; then
    log_this INFO "Running vulnerability ECR scan."
    _run_vulnerability_scan_with_ecr "${report_file_path}"
  fi
}

function retag_built_service_images() {
  set -eu -o pipefail -E

  local scan_path="$1"
  local new_image_tag="$2"

  while read -r docker_data_file; do

    log_this INFO "Processing ${docker_data_file}"

    local region
    local registry_id
    local repository_name
    local image_tag
    local manifest

    region="$(jq -r '.region' "${docker_data_file}")"
    registry_id="$(jq -r '.registry_id' "${docker_data_file}")"
    repository_name="$(jq -r '.repository_name' "${docker_data_file}")"
    image_tag="$(jq -r '.image_tag' "${docker_data_file}")"

    manifest="$(
      aws ecr batch-get-image \
        --region "${region}" \
        --registry-id "${registry_id}" \
        --repository-name "${repository_name}" \
        --image-ids "imageTag=${image_tag}" \
        --query "images[].imageManifest" \
        --output text
    )"

    aws ecr put-image \
      --region "${region}" \
      --registry-id "${registry_id}" \
      --repository-name "${repository_name}" \
      --image-tag "${new_image_tag}" \
      --image-manifest "${manifest}"

    log_this INFO "Re-tagged image ${repository_name}:${image_tag} as ${new_image_tag} in ${registry_id} / ${region}."

  done < <(find "${scan_path}" -type f -name "${REPORT_FILE_NAME}")

}

function remove_local_service_image() {
  set -eu -o pipefail -E
  docker rmi -f "$(get_build_tag "${SERVICE_NAME}")" 2>/dev/null || true
}
