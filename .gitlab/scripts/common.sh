function get_project_version() {

  # Version flavour can be:
  # - "incremental" - In this and any other case incremental ${CI_PIPELINE_ID} is returned
  # - "cached"      - In this case value of ${CI_COMMIT_REF_SLUG} is returned as version.
  #                   This is good for caching images across builds when working on a branch.
  # - "stable"      - Use with `master` branch builds only! This is to tag "latest stable" releases in Retag Job
  #                   once entire pipeline finishes successfully. In this case the tag will end with `:stable`
  #                   and will get updated every time a pipeline succeeds, assuming the post-release jobs are enabled.
  #
  # Note that the  _"Living"_ version tags (`cached`, `stable`) will not work on `release` ECR Repositories
  # as those are specifically deployed with `IMMUTABLE` setting and will not allow overwriting existing tags.

  local flavour="${1:-""}"

  case "${flavour}" in
    incremental)
      echo "${CI_PIPELINE_ID}"
      ;;
    cached)
      echo "${CI_COMMIT_REF_SLUG}"
      ;;
    stable)
      echo "stable"
      ;;
  esac
}

function _docker_login_to_gitlab() {
  log_debug_variable CI_REGISTRY_USER "${CI_REGISTRY_USER}"
  log_debug_variable CI_REGISTRY_PASSWORD "${CI_REGISTRY_PASSWORD}"
  log_debug_variable CI_REGISTRY "${CI_REGISTRY}"

  log_this INFO "Logging in to Gitlab registry: ${CI_REGISTRY}"
  echo "${CI_REGISTRY_PASSWORD}" \
    | docker login -u "${CI_REGISTRY_USER}" --password-stdin "${CI_REGISTRY}"
}

function _docker_login_to_dockerhub() {
  log_debug_variable DOCKERHUB_USERNAME "${DOCKERHUB_USERNAME}"
  log_debug_variable DOCKERHUB_PASSWORD "${DOCKERHUB_PASSWORD}"
  log_debug_variable DOCKERHUB_REGISTRY "${DOCKERHUB_REGISTRY}"

  log_this INFO "Logging in to Docker Hub registry: ${DOCKERHUB_REGISTRY}"
  echo "${DOCKERHUB_PASSWORD}" \
    | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin "${DOCKERHUB_REGISTRY}"
}

function _docker_login_to_ecr() {

  local region="$1"
  local account_ids="$2"

  log_this INFO "Logging in to ECR in region ${region} and accounts: ${account_ids}"

  for account_id in ${account_ids}; do
    aws ecr get-login-password --region "${region}" \
      | docker login -u AWS --password-stdin "https://${account_id}.dkr.ecr.${region}.amazonaws.com"
  done
}

function docker_login() {
  local docker_registry="$1"; shift

  if [[ "${LOCAL_BUILD:-"false"}" == "true" ]]; then
      log_this WARN "Local docker registry. No login."
      return
  fi

  case "${docker_registry}" in
    dockerhub)
      _docker_login_to_dockerhub "$@"
      ;;
    ecr)
      _docker_login_to_ecr "$@"
      ;;
    gitlab)
      _docker_login_to_gitlab "$@"
      ;;
    *)
      log_this ERROR "Unexpected value of docker_registry: ${docker_registry}."
      exit 1
      ;;
  esac
}

function get_build_tag() {
  # Returns temporary build tag, to tag the new image.
  # This image will later be re-tagged to proper service_image_uri, and pushed to different repositories

  # INFRA-572: Because those images are in fact built on a shared Gitlab Runner, to prevent overriding them
  # when two jobs of the same repository run on the same runner, we additionally add a discriminator, which
  # will be the incremental project version (i.e. CI_PIPELINE_ID) to make sure each image is tagged differently.

  local name="$1"
  local discriminator

  discriminator="$(get_project_version "incremental")"

  echo "${name}:current-build-${discriminator}"
}

function get_dockerfile_path() {
  local name="$1"
  local value

  if [[ "${DOCKERFILE_PATH}" != "" ]]; then
    value="${DOCKERFILE_PATH}"
  else
    value="docker/${name}/Dockerfile"
  fi

  echo "${value}"
}

function get_docker_target() {
  local name="$1"
  local value

  if [[ "${DOCKER_TARGET}" != "" ]]; then
    value="${DOCKER_TARGET}"
  else
    value="${name}"
  fi

  echo "${value}"
}

function pull_image() {
  local image=$1

  log_this INFO "Attempting to pull existing image: ${image}"
  docker pull "${image}" 2>/dev/null || true
}

function configure_docker_build() {
  # Loads BASE / PIPELINE images if needed.
  # Configures docker build args.

  local image_base="${1:-"${IMAGE_BASE}"}"
  local image_pipeline="${2:-"${IMAGE_PIPELINE}"}"
  local image_base_pipeline="${3:-"${IMAGE_BASE_PIPELINE}"}"
  local pipeline_args=""

  docker_login "gitlab"

  if [[ "${INJECT_TO_PROJECT_IMAGES}" == "true" ]] ; then
    pull_image "${image_base}"
    pipeline_args="${pipeline_args} --build-arg IMAGE_BASE=${image_base}"

    pull_image "${image_pipeline}"
    pipeline_args="${pipeline_args} --build-arg IMAGE_PIPELINE=${image_pipeline}"
  fi

  if [[ "${INJECT_TO_PROJECT_IMAGES}" != "true" ]] ; then
    pull_image "${image_base_pipeline}"
    pipeline_args="${pipeline_args} --build-arg IMAGE_BASE_PIPELINE=${image_base_pipeline}"
  fi

  if [[ "${USE_LOG_LEVEL_ARG}" == "true" ]]; then
    pipeline_args="${pipeline_args} --build-arg LOG_LEVEL"
  fi

  # shellcheck disable=SC2154
  pipeline_args="${pipeline_args} --build-arg PROJECT_VERSION=$(get_project_version "incremental")"
  # shellcheck disable=SC2034
  BUILD_ARGS_EXTRA="${BUILD_ARGS_EXTRA:-""} ${pipeline_args}"
}

function configure_docker_dind() {
  # Configure connection to docker dind using image pipeline and check if docker dind is responding
  # If docker dind is not responding that means we are using runners that not support docker dind configuration
  # (runners deployed by ST) we need then unset all configuration and try use docker daemon directly from host runner.
  # This configuration is for handle both cases for building docker images (with / without docker dind)
  # without knowing what type runner we are using.

  log_this INFO "Configure docker DIND"
  export DOCKER_HOST="tcp://docker:2376"
  export DOCKER_TLS_VERIFY="1"
  export DOCKER_CERT_PATH="${DOCKER_TLS_CERTDIR}/client"

  set +e
  docker -H=tcp://docker:2376 version >/dev/null 2>&1
  result=$?
  set -e

  if [[ "${result}" -ne 0 ]]; then
    log_this INFO "Docker DIND is not running unset variable"
    unset DOCKER_HOST
    unset DOCKER_TLS_VERIFY
    unset DOCKER_CERT_PATH
  else
    # Required DIND configuration
    log_this INFO "Docker DIND is running"
  fi
}