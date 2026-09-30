# xiao-scripts

提供三个用于服务器 SSH 与防火墙配置的 Bash 脚本。按需要选择：

| 脚本 | 用途 | 修改 SSH 配置 | 修改 UFW |
| --- | --- | --- | --- |
| [`setup-ssh.sh`](./setup-ssh.sh) | 添加内置公钥并配置仅密钥登录 | 是 | 否 |
| [`setup-ufw.sh`](./setup-ufw.sh) | 安装并加固 UFW | 否 | 是，会重置现有规则 |
| [`setup-ssh-ufw.sh`](./setup-ssh-ufw.sh) | 同时配置 SSH 密钥登录与 UFW | 是 | 是，会重置现有规则 |

三个脚本都需要 root 权限。SSH 脚本会把仓库内置公钥加入 `/root/.ssh/authorized_keys`，重复运行不会重复添加。

## 只配置 SSH 密钥登录：`setup-ssh.sh`

从 GitHub Raw 地址直接运行：

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ssh.sh)
```

也可以先下载，再执行：

```bash
curl -fsSLo setup-ssh.sh https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ssh.sh
sudo bash setup-ssh.sh
```

脚本会禁用 SSH 密码和键盘交互认证，并限制 root 仅通过公钥登录；不会修改 UFW，也不会安装软件包。

## 只配置 UFW：`setup-ufw.sh`

不传参数时进入交互模式，依次询问需要开放的 TCP 端口，以及是否开放 `2096/tcp`（默认开放）：

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ufw.sh)
```

也可以使用非交互模式。以下示例开放 `39412/tcp`，并默认开放 `2096/tcp`：

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ufw.sh) 39412
```

不开放 `2096/tcp`：

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ufw.sh) 39412 --no-2096
```

如果脚本已下载到本地，将 Raw 命令中的进程替换部分换成 `setup-ufw.sh` 即可。

## 同时配置 SSH 与 UFW：`setup-ssh-ufw.sh`

不传参数时进入交互模式：

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ssh-ufw.sh)
```

非交互模式的端口参数与 `setup-ufw.sh` 相同：

```bash
# 开放 39412/tcp，并默认开放 2096/tcp
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ssh-ufw.sh) 39412

# 开放 39412/tcp，但不开放 2096/tcp
sudo bash <(curl -fsSL https://raw.githubusercontent.com/topxiao/xiao-scripts/main/setup-ssh-ufw.sh) 39412 --no-2096
```

## UFW 规则

两个涉及 UFW 的脚本都会先安装 UFW，再重置全部现有规则，然后设置：

- 默认拒绝入站连接，允许出站连接。
- 开放 `22/tcp`、`443/tcp`、`443/udp` 和指定的额外 TCP 端口。
- 默认开放 `2096/tcp`；传入 `--no-2096` 或在交互提示中选择 `n` 时跳过。

## 执行前注意

- UFW 脚本会清除服务器上已有的全部 UFW 规则。运行前确认没有其他必须保留的规则。
- UFW 配置只放行 `22/tcp` 作为 SSH 端口。如果服务器 SSH 使用其他端口，需先调整脚本中的规则，避免远程连接中断。
- SSH 脚本会禁用密码登录。运行后保持当前 SSH 会话，验证公钥登录正常后再断开。
- 脚本内置的是 SSH 公钥，不包含私钥。
- 脚本面向使用 `systemctl` 和 `sshd_config.d` 的 Debian/Ubuntu 系统；其他发行版可能需要调整服务名或配置路径。
