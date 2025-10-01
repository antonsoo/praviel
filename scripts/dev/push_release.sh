#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WITH_GIT="${ROOT}/scripts/dev/with_git_env.sh"
SSH_AGENT="${ROOT}/scripts/dev/ssh_agent.sh"

"${WITH_GIT}"

ssh_status=0
ssh_output="$(${SSH_AGENT} 2>&1)" || ssh_status=$?
printf '%s
' "${ssh_output}"
if [[ ${ssh_status} -eq 2 ]]; then
  echo '::PUSH::FAIL::SSH_LOCKED'
  exit 2
fi
if [[ ${ssh_status} -ne 0 ]]; then
  echo '::PUSH::FAIL::SSH_ERROR'
  exit ${ssh_status}
fi

if ! (cd "${ROOT}" && pre-commit run --all-files); then
  echo '::PUSH::FAIL::PRECOMMIT'
  exit 1
fi

if ! (cd "${ROOT}" && git push origin HEAD:main); then
  echo '::PUSH::FAIL::GIT_MAIN'
  exit 1
fi

if ! (cd "${ROOT}" && git push --tags); then
  echo '::PUSH::FAIL::GIT_TAGS'
  exit 1
fi

echo '::PUSH::OK'
