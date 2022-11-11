#!/usr/bin/env bash

set -o allexport
source .env
set +o allexport

function install() {
  install_k3d
  install_dlv
}
function install_dlv() {
  if [ ! -f ./delve/bin/dlv ] ; then
    git clone https://github.com/go-delve/delve
    cd delve || exit 1
    go build -o ./bin/dlv cmd/dlv/main.go
    cd .. || exit 1
  fi
  echo "Installed: $(./delve/bin/dlv version)"
}

function version_check() {
  printf '%s\n%s\n' "$2" "$1" | sort --check=quiet --version-sort
}

function get_k3d_version() {
  k3d version | grep k3d | awk '{print$3}'
}

function install_k3d() {
  local ver
  if [ "" == "$(which k3d)" ] ; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
      | TAG="${K3D_VERSION}" bash
    return
  fi
  ver="$(get_k3d_version)"
  if version_check "v5.3.0" "${ver}" ; then
    echo
    echo "ERROR: k3d must be v5.3.0 greater or this build will fail."
    echo
    echo "If you delete $(which k3d) and then run make again it will install k3d ${K3D_VERSION} for you."
    echo
    exit 1
  fi
  echo "Installed: $(k3d version)"
}

function maybe_dot_prefix() {
  if [[ "" == "${ext}" || "." == "${ext:0:1}" ]] ; then
    echo "${ext}"
    return
  fi
  echo ".${ext}"
}

function generate_file() {
  local name="$1"
  local ext="$2"

  ext="$(maybe_dot_prefix "${ext}")"
  # shellcheck disable=SC2145
  (
    echo "# DO NOT EDIT — This file was generated."
    echo "#"
    echo "#   Edit ${name}${ext}.tmpl instead."
    echo "#"
    echo "# ---------------------------------------------"
    echo "#"
    envsubst < "./${name}${ext}.tmpl"
  ) > "./${name}${ext}"
}

function init() {
  if [ "" == "$(k3d registry list | grep k3d-registry.localhost)" ] ; then
    if ! k3d registry create registry.localhost -p 5000 ; then
      return
    fi
  else
    k3d registry list
  fi
  if [ "" == "$(k3d cluster list | grep debuggable-cluster)" ] ; then
    generate_file k3d yaml
    if ! k3d cluster create debuggable-cluster \
        --config ./k3d.yaml ; then
      return
    fi
  else
    k3d cluster list
  fi
}


function cli_debug() {
  ./delve/bin/dlv connect "localhost:${DLV_EXTERNAL_PORT}" --log
}

function kill_app() {
  echo -e "q\ny" \
    | ./delve/bin/dlv connect "localhost:${DLV_EXTERNAL_PORT}"
}

function build_docker() {
  generate_file Dockerfile
  docker build -t debuggable-app-image .
}

function create_docker() {
    docker create \
      --name debuggable-app-container \
      -p "${DLV_EXTERNAL_PORT}:${DLV_CONTAINER_PORT}" \
      --security-opt="apparmor=unconfined" \
      --cap-add=SYS_PTRACE \
      debuggable-app-image
}

function start_docker() {
	docker start debuggable-app-container
}

function clean_docker() {
	docker rm debuggable-app-container 2>/dev/null || true
}
function tag_docker() {
	docker image tag \
		debuggable-app-image \
		k3d-registry.localhost:5000/debuggable-app-image:latest
}
function push_docker() {
	docker image push \
		k3d-registry.localhost:5000/debuggable-app-image:latest
}

function clean_files() {
  rm -f Dockerfile
  rm -f k3d.yaml
  rm -f pod.yaml
  rm -rf delve
}

function clean_k3d() {
  k3d registry delete k3d-registry.localhost 2>/dev/null || true
  k3d cluster delete debuggable-cluster 2>/dev/null || true
}
function apply_kubectl() {
  generate_file pod yaml
	kubectl delete -f pod.yaml 2>/dev/null || true
	kubectl apply -f pod.yaml
}

function main() {
  case "$1" in
  install)            install       ;;
  init)               init          ;;
  cli-debug)          cli_debug     ;;
  kill-app)           kill_app      ;;
  build-docker)       build_docker  ;;
  create-docker)      create_docker ;;
  tag-docker)         tag_docker    ;;
  push-docker)        push_docker   ;;
  clean-files)        clean_files   ;;
  clean-docker)       clean_docker  ;;
  clean-k3d)          clean_k3d     ;;
  apply-kubectl)      apply_kubectl ;;
  esac

}
main "$@"
