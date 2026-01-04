#!/bin/bash
# Linux frps 卸载脚本
# 完全删除 frps 及相关配置

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Font="\033[0m"

# variable
FRP_NAME=frps
FRP_PATH=/usr/local/frp

# check root
if [ "$(id -u)" != "0" ]; then
    echo -e "${Red}错误: 请使用 root 用户运行此脚本${Font}"
    exit 1
fi

echo -e "${Yellow}正在卸载 ${FRP_NAME}...${Font}"

# 停止并禁用服务
echo -e "${Green}停止 ${FRP_NAME} 服务...${Font}"
systemctl stop ${FRP_NAME} 2>/dev/null
systemctl disable ${FRP_NAME} 2>/dev/null

# 删除 systemd 服务文件
echo -e "${Green}删除服务文件...${Font}"
rm -f /etc/systemd/system/${FRP_NAME}.service
rm -f /lib/systemd/system/${FRP_NAME}.service
systemctl daemon-reload

# 删除 frp 目录
echo -e "${Green}删除 ${FRP_PATH} 目录...${Font}"
rm -rf ${FRP_PATH}

# 删除管理脚本
echo -e "${Green}删除管理脚本...${Font}"
rm -f /usr/local/bin/frps-manager
rm -f /usr/local/bin/frps

# 删除本脚本
rm -f frps_linux_uninstall.sh 2>/dev/null

echo -e "${Green}============================${Font}"
echo -e "${Green}卸载成功,相关文件已清理完毕!${Font}"
echo -e "${Green}============================${Font}"
