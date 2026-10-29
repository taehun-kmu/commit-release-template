#!/usr/bin/env bash

# Purpose: release/<버전> 브랜치를 main에 병합했을 때 semantic-release가 낼 버전이
#          브랜치 이름의 <버전>과 같은지 확인
# Generated: 2026-10-29
# Usage: check-release-version.sh <release/X.Y.Z 브랜치 이름>
#   저장소 최상위의 node_modules와 원격(origin) 푸시 권한이 필요함
#   지금 저장소는 바꾸지 않음, 임시 복제본에서 main에 병합해 계산

set -euo pipefail

readonly ERROR_MISMATCH=1
readonly ERROR_INVALID_ARGUMENT=2
readonly ERROR_DEPENDENCY_MISSING=3
readonly ERROR_NO_RELEASE=4
readonly ERROR_CALCULATION_FAILED=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

log_info() {
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
  echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1" >&2
}

handle_error() {
  local error_code="$1"
  local error_message="$2"
  log_error "${error_message}"
  exit "${error_code}"
}

main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: check-release-version.sh <release/X.Y.Z>" >&2
    handle_error "${ERROR_INVALID_ARGUMENT}" "인자가 1개여야 함"
  fi

  local branch="$1"
  local regex='^release/([0-9]+\.[0-9]+\.[0-9]+)$'
  if [[ ! "${branch}" =~ ${regex} ]]; then
    handle_error "${ERROR_INVALID_ARGUMENT}" "브랜치 이름이 release/X.Y.Z 꼴이 아님: ${branch}"
  fi
  local expected="${BASH_REMATCH[1]}"

  local repo
  repo="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
  local bin="${repo}/node_modules/.bin/semantic-release"
  if [[ ! -x "${bin}" ]]; then
    handle_error "${ERROR_DEPENDENCY_MISSING}" "${bin}가 없음, 먼저 pnpm install"
  fi

  local remote_url
  remote_url="$(git -C "${repo}" remote get-url origin)"

  local work
  work="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${work}'" EXIT

  git clone -q "${repo}" "${work}/repo"
  cd "${work}/repo"
  git remote set-url origin "${remote_url}"
  git fetch -q --tags origin main "${branch}"
  git checkout -q -B main origin/main
  git -c user.name=check -c user.email=check@localhost -c commit.gpgsign=false \
    merge -q --no-ff --no-edit "origin/${branch}"
  ln -s "${repo}/node_modules" node_modules

  log_info "main에 ${branch}를 병합한 상태로 다음 버전 계산"
  local output
  if ! output="$("${bin}" --dry-run --no-ci --branches main \
    --plugins @semantic-release/commit-analyzer,@semantic-release/release-notes-generator 2>&1)"; then
    echo "${output}" >&2
    handle_error "${ERROR_CALCULATION_FAILED}" "semantic-release dry-run 실패"
  fi

  local actual
  actual="$(echo "${output}" | sed -n 's/.*the next release version is \([0-9][0-9.]*\).*/\1/ip' | tail -1)"
  if [[ -z "${actual}" ]]; then
    handle_error "${ERROR_NO_RELEASE}" "${branch}를 병합해도 릴리스가 없음 (feat, fix, BREAKING CHANGE 커밋 없음)"
  fi

  if [[ "${actual}" != "${expected}" ]]; then
    handle_error "${ERROR_MISMATCH}" "브랜치 이름 ${expected}, 실제 다음 버전 ${actual} → 브랜치 이름을 release/${actual}로 바꾸거나 커밋을 고침"
  fi

  log_info "같음: ${expected}"
}

main "$@"
