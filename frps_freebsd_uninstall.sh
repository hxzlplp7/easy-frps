#!/bin/sh
# FreeBSD frps uninstallation script for HostUno/Serv00 (non-root user)
# Adapted for shared hosting environment

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

# variable
FRP_NAME=frps
FRP_PATH="${HOME}/frp"

echo -e "${Yellow}正在卸载 ${FRP_NAME}...${Font}"

# stop frps service
echo -e "${Green}停止 ${FRP_NAME} 服务...${Font}"
if [ -f "${FRP_PATH}/stop.sh" ]; then
    ${FRP_PATH}/stop.sh
fi

# kill any remaining frps process
FRPSPID=$(pgrep -x ${FRP_NAME} 2>/dev/null)
if [ -n "$FRPSPID" ]; then
    echo -e "${Yellow}强制停止 ${FRP_NAME} 进程 (pid: ${FRPSPID})...${Font}"
    kill -9 $FRPSPID 2>/dev/null
fi

# remove from crontab
echo -e "${Green}从 crontab 中移除自启动...${Font}"
crontab -l 2>/dev/null | grep -v "${FRP_PATH}/start.sh" | crontab -

# remove frp directory
echo -e "${Green}删除 ${FRP_PATH} 目录...${Font}"
if [ -d "${FRP_PATH}" ]; then
    rm -rf ${FRP_PATH}
    echo -e "${Green}已删除 ${FRP_PATH}${Font}"
else
    echo -e "${Yellow}目录 ${FRP_PATH} 不存在${Font}"
fi

echo -e "${Green}============================${Font}"
echo -e "${Green}卸载成功,相关文件已清理完毕!${Font}"
echo -e "${Green}============================${Font}"
