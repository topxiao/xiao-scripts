# xiao-scripts

用于初始化 Debian/Ubuntu 服务器的 SSH 与 UFW 加固脚本。

## 使用方式

将 [setup-ssh-ufw.sh](./setup-ssh-ufw.sh) 复制到目标服务器后，以 root 权限执行：

```bash
chmod 700 setup-ssh-ufw.sh
sudo bash setup-ssh-ufw.sh
```

不传参数时，脚本会依次询问要开放的 TCP 端口，以及是否开放 `2096/tcp`；后者默认开放。

也可以使用非交互模式：

```bash
# 开放 39412/tcp，并默认开放 2096/tcp
sudo bash setup-ssh-ufw.sh 39412

# 开放 39412/tcp，但不开放 2096/tcp
sudo bash setup-ssh-ufw.sh 39412 --no-2096
```

## 脚本行为

- 将脚本内置的 SSH 公钥写入 `/root/.ssh/authorized_keys`（重复执行不会重复添加）。
- 禁用 SSH 密码和键盘交互认证，允许 root 仅使用 SSH 公钥认证。
- 删除 `/etc/ssh/sshd_config.d/99-hardening.conf`，并写入 `00-hardening.conf`。
- 重置全部现有 UFW 规则，再开放 `22/tcp`、`443/tcp`、`443/udp`、指定 TCP 端口，以及默认的 `2096/tcp`。

## 注意事项

脚本会重置现有 UFW 规则并关闭 SSH 密码登录。请保持当前 SSH 会话不断开，确认新公钥能正常登录后再退出当前会话。

脚本适用于使用 `systemctl reload ssh` 的 Debian/Ubuntu 系统；其他发行版可能需要调整 SSH 服务名称或软件包管理命令。
