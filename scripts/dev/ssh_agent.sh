#!/usr/bin/env bash
set -euo pipefail

check_identities() {
  if ssh-add -l >/dev/null 2>&1; then
    return 0
  fi
  return $?
}

start_agent_if_needed() {
  local status
  check_identities
  status=$?
  if [[ $status -ne 2 ]]; then
    return $status
  fi

  eval "$(ssh-agent)" >/dev/null
  check_identities
  return $?
}

try_add_default_keys() {
  local keydir="${HOME:-}/.ssh"
  [[ -d "${keydir}" ]] || return 1
  local key
  for key in id_ed25519 id_rsa id_ecdsa id_dsa; do
    local path="${keydir}/${key}"
    [[ -f "${path}" ]] || continue
    if SSH_ASKPASS=/bin/false SSH_ASKPASS_REQUIRE=force DISPLAY=none ssh-add -q "${path}" </dev/null >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

status=$(start_agent_if_needed)
if [[ ${status} -eq 0 ]]; then
  echo '::SSH::READY'
  exit 0
fi

if [[ ${status} -ne 1 ]]; then
  echo '::SSH::FAIL'
  exit 1
fi

if try_add_default_keys; then
  if ssh-add -l >/dev/null 2>&1; then
    echo '::SSH::READY'
    exit 0
  fi
fi

echo '::SSH::LOCKED'
exit 2
