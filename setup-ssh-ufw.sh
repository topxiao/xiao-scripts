#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<EOF
用法：
  sudo bash $0                         # 交互式执行
  sudo bash $0 <端口号>                # 默认开放 2096/tcp
  sudo bash $0 <端口号> --no-2096      # 不开放 2096/tcp
EOF
}

normalize_port() {
  local input="$1"
  local port

  [[ "$input" =~ ^[0-9]+$ ]] || return 1
  (( ${#input} <= 5 )) || return 1

  port=$((10#$input))
  (( port >= 1 && port <= 65535 )) || return 1

  printf '%s\n' "$port"
}

prompt_for_options() {
  local input normalized choice

  while true; do
    read -r -p "请输入需要开放的 TCP 端口: " input || exit 1

    if normalized="$(normalize_port "$input")"; then
      APP_PORT="$normalized"
      break
    fi

    echo "端口无效，请输入 1–65535 之间的数字。"
  done

  while true; do
    read -r -p "是否开放 2096/tcp？[Y/n]: " choice || exit 1

    case "${choice,,}" in
      ""|y|yes)
        OPEN_2096=true
        break
        ;;
      n|no)
        OPEN_2096=false
        break
        ;;
      *)
        echo "请输入 Y 或 n。"
        ;;
    esac
  done
}

if [[ $EUID -ne 0 ]]; then
  echo "请用 root 身份执行。"
  usage
  exit 1
fi

APP_PORT=""
OPEN_2096=true

case "$#" in
  0)
    prompt_for_options
    ;;
  1)
    APP_PORT="$(normalize_port "$1")" || {
      echo "端口无效：$1"
      exit 1
    }
    ;;
  2)
    APP_PORT="$(normalize_port "$1")" || {
      echo "端口无效：$1"
      exit 1
    }

    if [[ "$2" != "--no-2096" ]]; then
      usage
      exit 1
    fi

    OPEN_2096=false
    ;;
  *)
    usage
    exit 1
    ;;
esac

KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDvBopJGV/QStCDi5tnslttHBxy7YBs38QoTWMULmnC'

# ===== 添加 SSH 公钥 =====
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
grep -Fqx "$KEY" /root/.ssh/authorized_keys || printf '%s\n' "$KEY" >> /root/.ssh/authorized_keys

# ===== SSH 加固 =====
rm -f /etc/ssh/sshd_config.d/99-hardening.conf

cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
PermitEmptyPasswords no
EOF

sshd -t
systemctl reload ssh

# ===== UFW 加固 =====
apt update
apt install -y ufw

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 443/udp

if [[ "$OPEN_2096" == true ]]; then
  ufw allow 2096/tcp
fi

ufw allow "${APP_PORT}/tcp"
ufw --force enable

# ===== 检查 =====
echo "===== SSH ====="
sshd -T | grep -E '^(permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication)'

echo "===== UFW ====="
ufw status

echo "===== PORTS ====="
ss -tunlp | grep -E ":(22|443|2096|${APP_PORT})\\b" || true
