#!/usr/bin/env bash
set -euo pipefail
KEY="${1:-$HOME/.ssh/id_ed25519}"
: "${AI_AGENT_SSH_PASSPHRASE:?set AI_AGENT_SSH_PASSPHRASE}"
eval "$(ssh-agent -s)"
trap 'rm -f "$ASKPASS"' EXIT
ASKPASS="$(mktemp)"
cat >"$ASKPASS" <<'EOF'
#!/usr/bin/env bash
printf "%s" "$AI_AGENT_SSH_PASSPHRASE"
EOF
chmod +x "$ASKPASS"
export SSH_ASKPASS="$ASKPASS" SSH_ASKPASS_REQUIRE=force DISPLAY=dummy:0
ssh-add "$KEY"
