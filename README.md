# frps 一键安装脚本

## 项目简介

基于 [fatedier/frp](https://github.com/fatedier/frp) 原版 frp 内网穿透服务端 frps 的一键安装脚本。

支持 **Linux VPS/NAT机** 和 **FreeBSD (HostUno/Serv00)** 两种环境，提供：
- ✅ **交互式配置** - 傻瓜式引导安装
- ✅ **强密码生成** - 自动生成32位安全Token
- ✅ **自动保活** - 进程异常自动重启
- ✅ **管理面板** - 命令行图形化管理界面
- ✅ **开机自启** - 系统重启后自动运行

## 支持系统

| 系统 | 脚本 | 备注 |
|------|------|------|
| **Linux** | `frps_linux_install.sh` | Debian/Ubuntu/CentOS/Alpine 等 |
| **FreeBSD** | `frps_freebsd_install.sh` | HostUno/Serv00 等共享主机 |

## 快速开始

### Linux VPS/NAT机 安装

```bash
# 一键安装 (请使用 root 用户运行)
wget https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_linux_install.sh && bash frps_linux_install.sh
```

或使用国内镜像：
```bash
wget https://ghfast.top/https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_linux_install.sh && bash frps_linux_install.sh
```

### FreeBSD (HostUno/Serv00) 安装

> ⚠️ **重要提示**：安装前请先在 HostUno 控制面板的 `Port reservation` 中预约端口！

```bash
# 一键安装
wget https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_freebsd_install.sh && chmod +x frps_freebsd_install.sh && ./frps_freebsd_install.sh
```

或使用国内镜像：
```bash
wget https://ghfast.top/https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_freebsd_install.sh && chmod +x frps_freebsd_install.sh && ./frps_freebsd_install.sh
```

## 管理命令

安装完成后，输入 `frps` 即可进入管理面板：

```
==================== 管理菜单 ====================
1. 启动 frps
2. 停止 frps
3. 重启 frps
4. 查看状态
5. 查看日志
6. 查看配置
7. 编辑配置
8. 连接信息
9. 放行防火墙 (仅Linux)
10. 卸载 frps
0. 退出
==================================================
```

### 快捷命令

```bash
frps              # 进入管理面板
frps start        # 启动服务
frps stop         # 停止服务
frps restart      # 重启服务
frps status       # 查看状态
frps log          # 实时日志
frps info         # 显示连接信息
```

### 快捷命令失效怎么办？

如果输入 `frps` 提示 `command not found`，请尝试以下方法：

**方法一：重新加载 Shell 配置**
```bash
# Linux (bash)
source ~/.bashrc

# FreeBSD (HostUno/Serv00)
source ~/.profile
```

**方法二：重新运行安装脚本**
```bash
# 重新运行对应系统的安装脚本，会自动修复快捷命令
./frps_linux_install.sh      # Linux
./frps_freebsd_install.sh    # FreeBSD
```

**方法三：手动创建快捷命令**
```bash
# Linux
echo 'alias frps="/usr/local/frp/frps_manager.sh"' >> ~/.bashrc && source ~/.bashrc

# FreeBSD
echo 'alias frps="$HOME/frp/frps_manager.sh"' >> ~/.profile && source ~/.profile
```

### Linux 额外命令

```bash
systemctl status frps   # 查看状态
systemctl restart frps  # 重启服务
journalctl -u frps -f   # 查看日志
```

## 卸载

### Linux
```bash
wget https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_linux_uninstall.sh && bash frps_linux_uninstall.sh
```

### FreeBSD
```bash
wget https://raw.githubusercontent.com/hxzlplp7/easy-frps/main/frps_freebsd_uninstall.sh && chmod +x frps_freebsd_uninstall.sh && ./frps_freebsd_uninstall.sh
```

或直接在管理面板中选择 `卸载 frps`。

## 端口说明

| 端口 | 配置项 | 作用 | 是否必须 |
|------|--------|------|----------|
| **绑定端口** | `bindPort` | frpc 客户端连接端口 | ✅ 必须 |
| **Dashboard** | `webServer.port` | Web 管理面板 | ✅ 推荐 |
| **HTTP** | `vhostHTTPPort` | HTTP 代理端口 | ❌ 可选 |
| **HTTPS** | `vhostHTTPSPort` | HTTPS 代理端口 | ❌ 可选 |

## 版本对比

| 功能 | Linux 版本 | FreeBSD 版本 |
|------|------------|--------------|
| 权限要求 | root | 普通用户 |
| 安装路径 | `/usr/local/frp` | `~/frp` |
| 服务管理 | systemd | crontab 保活 |
| 防火墙配置 | 自动 | 手动 |
| 管理界面 | ✅ | ✅ |
| 强密码生成 | ✅ | ✅ |
| 开机自启 | ✅ | ✅ |

## 文件列表

```
frps_linux_install.sh      # Linux 安装脚本
frps_linux_uninstall.sh    # Linux 卸载脚本
frps_freebsd_install.sh    # FreeBSD 安装脚本
frps_freebsd_uninstall.sh  # FreeBSD 卸载脚本
```

## 相关链接

- 原版 frp 项目：[fatedier/frp](https://github.com/fatedier/frp)
- frp 官方文档：[https://gofrp.org/](https://gofrp.org/)

## License

MIT License