#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "请用 root 身份执行：sudo bash $0"
  exit 1
fi

if (( $# > 0 )); then
  echo "用法：sudo bash $0"
  exit 1
fi

KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDvBopJGV/QStCDi5tnslttHBxy7YBs38QoTWMULmnC'
SSH_DIR='/root/.ssh'
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
SSHD_CONFIG_DIR='/etc/ssh/sshd_config.d'
HARDENING_CONFIG="${SSHD_CONFIG_DIR}/00-hardening.conf"

# ===== 添加 SSH 公钥 =====
install -d -m 700 "$SSH_DIR"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"
grep -Fqx "$KEY" "$AUTHORIZED_KEYS" || printf '%s\n' "$KEY" >> "$AUTHORIZED_KEYS"

# ===== 仅允许 SSH 密钥认证 =====
install -d -m 755 "$SSHD_CONFIG_DIR"
TEMP_CONFIG="${SSHD_CONFIG_DIR}/.00-hardening.conf.$(date -u +%Y%m%dT%H%M%S%NZ)"
umask 077
set -o noclobber
: > "$TEMP_CONFIG"
set +o noclobber
trap 'rm -f "$TEMP_CONFIG"' EXIT

cat > "$TEMP_CONFIG" <<'EOF'
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
PermitEmptyPasswords no
EOF

chmod 644 "$TEMP_CONFIG"
mv -f "$TEMP_CONFIG" "$HARDENING_CONFIG"
trap - EXIT

sshd -t

if systemctl is-active --quiet ssh; then
  systemctl reload ssh
elif systemctl is-active --quiet sshd; then
  systemctl reload sshd
else
  echo "未找到运行中的 ssh 或 sshd 服务；配置已写入，但服务未重载。" >&2
  exit 1
fi

echo "SSH 公钥登录配置完成。"
sshd -T | grep -E '^(authenticationmethods|permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication)'
