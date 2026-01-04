#!/bin/sh
# FreeBSD frps 一键安装脚本 (HostUno/Serv00 专用)
# 交互式配置 + 自动保活 + 管理界面

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[34m"
Cyan="\033[36m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
BlueBG="\033[44;37m"
Font="\033[0m"

# variable
FRP_VERSION=0.65.0
REPO=stilleshan/frps
WORK_PATH=$(pwd)
FRP_NAME=frps
FRP_PATH="${HOME}/frp"
BIN_PATH="${HOME}/bin"
PROXY_URL="https://ghfast.top/"

clear
echo -e "${BlueBG}                                                                    ${Font}"
echo -e "${BlueBG}          HostUno/Serv00 FreeBSD frps 一键安装脚本                  ${Font}"
echo -e "${BlueBG}                    交互式配置 + 自动保活                           ${Font}"
echo -e "${BlueBG}                                                                    ${Font}"
echo ""

# check frps
if [ -f "${FRP_PATH}/${FRP_NAME}" ]; then
    echo -e "${Yellow}检测到已安装 frps，是否重新安装？${Font}"
    echo -e "${Red}警告: 这将删除现有配置！${Font}"
    printf "输入 y 继续，其他键退出: "
    read confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${Green}已取消安装${Font}"
        exit 0
    fi
    # stop existing frps
    pkill -x frps 2>/dev/null
    rm -rf ${FRP_PATH}
fi

# ==================== 交互式配置 ====================
echo ""
echo -e "${Cyan}==================== 配置 frps 服务端 ====================${Font}"
echo ""

# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "")
if [ -z "$SERVER_IP" ]; then
    echo -e "${Yellow}无法自动获取服务器IP，请手动输入${Font}"
    printf "请输入服务器公网IP: "
    read SERVER_IP
fi
echo -e "${Green}服务器IP: ${SERVER_IP}${Font}"

# 绑定端口
echo ""
echo -e "${RedBG} 重要提示 ${Font}"
echo -e "${Yellow}HostUno/Serv00 共享主机有端口限制!${Font}"
echo -e "${Cyan}请先在 HostUno 面板 -> Port reservation 中预约端口${Font}"
echo -e "${Cyan}只能使用您已预约的端口，否则会绑定失败!${Font}"
echo ""
echo -e "${Yellow}请输入 frps 绑定端口 (客户端连接用)${Font}"
printf "绑定端口 [必填，无默认值]: "
read BIND_PORT
while [ -z "$BIND_PORT" ]; do
    echo -e "${Red}端口不能为空!${Font}"
    printf "绑定端口: "
    read BIND_PORT
done

# Dashboard 端口
echo ""
echo -e "${Yellow}请输入 Dashboard 管理面板端口${Font}"
printf "Dashboard 端口 [必填]: "
read DASHBOARD_PORT
while [ -z "$DASHBOARD_PORT" ]; do
    echo -e "${Red}端口不能为空!${Font}"
    printf "Dashboard 端口: "
    read DASHBOARD_PORT
done

# Dashboard 用户名
echo ""
printf "Dashboard 用户名 [默认 admin]: "
read DASHBOARD_USER
DASHBOARD_USER=${DASHBOARD_USER:-admin}

# Dashboard 密码
echo ""
echo -e "${Yellow}Dashboard 密码${Font}"
printf "密码 [留空自动生成强密码]: "
read DASHBOARD_PWD
if [ -z "$DASHBOARD_PWD" ]; then
    # 生成 16 位强密码：大小写字母 + 数字 + 特殊字符
    DASHBOARD_PWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c 16)
    echo -e "${Green}已生成强密码: ${DASHBOARD_PWD}${Font}"
fi

# Token 认证
echo ""
echo -e "${Yellow}请设置 Token (客户端连接认证密钥)${Font}"
printf "Token [留空自动生成强密钥]: "
read AUTH_TOKEN
if [ -z "$AUTH_TOKEN" ]; then
    # 生成 32 位强 Token：大小写字母 + 数字 + 特殊字符
    AUTH_TOKEN=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*_+-' < /dev/urandom | head -c 32)
    echo -e "${Green}已生成强 Token (32位): ${AUTH_TOKEN}${Font}"
fi

# HTTP 代理端口 (可选)
echo ""
echo -e "${Yellow}HTTP 代理端口 (用于 Web 服务，可选)${Font}"
echo -e "${Cyan}如果不需要 HTTP 代理，直接回车跳过${Font}"
printf "HTTP 端口 [留空跳过]: "
read VHOST_HTTP_PORT

# HTTPS 代理端口 (可选)
echo ""
echo -e "${Yellow}HTTPS 代理端口 (可选)${Font}"
echo -e "${Cyan}如果不需要 HTTPS 代理，直接回车跳过${Font}"
printf "HTTPS 端口 [留空跳过]: "
read VHOST_HTTPS_PORT

# ==================== 确认配置 ====================
echo ""
echo -e "${Cyan}==================== 配置确认 ====================${Font}"
echo -e "${Green}服务器 IP:        ${Font}${SERVER_IP}"
echo -e "${Green}绑定端口:         ${Font}${BIND_PORT}"
echo -e "${Green}Dashboard 端口:   ${Font}${DASHBOARD_PORT}"
echo -e "${Green}Dashboard 用户:   ${Font}${DASHBOARD_USER}"
echo -e "${Green}Dashboard 密码:   ${Font}${DASHBOARD_PWD}"
echo -e "${Green}Token:            ${Font}${AUTH_TOKEN}"
if [ -n "$VHOST_HTTP_PORT" ]; then
    echo -e "${Green}HTTP 端口:        ${Font}${VHOST_HTTP_PORT}"
else
    echo -e "${Yellow}HTTP 端口:        ${Font}未配置"
fi
if [ -n "$VHOST_HTTPS_PORT" ]; then
    echo -e "${Green}HTTPS 端口:       ${Font}${VHOST_HTTPS_PORT}"
else
    echo -e "${Yellow}HTTPS 端口:       ${Font}未配置"
fi
echo ""
printf "确认以上配置? (y/n) [默认 y]: "
read confirm
confirm=${confirm:-y}
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${Red}已取消安装，请重新运行脚本${Font}"
    exit 0
fi

# ==================== 下载安装 ====================
echo ""
echo -e "${Cyan}==================== 开始下载安装 ====================${Font}"

# check arch
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        PLATFORM=amd64
        ;;
    aarch64|arm64)
        PLATFORM=arm64
        ;;
    *)
        echo -e "${Red}不支持的系统架构: ${ARCH}${Font}"
        exit 1
        ;;
esac

FILE_NAME=frp_${FRP_VERSION}_freebsd_${PLATFORM}
echo -e "${Green}系统架构: ${PLATFORM}${Font}"

cd ${WORK_PATH}

# download
echo -e "${Green}正在下载 frp ${FRP_VERSION}...${Font}"
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com" 2>/dev/null)

if [ "$GOOGLE_HTTP_CODE" = "200" ]; then
    curl -L -o ${FILE_NAME}.tar.gz https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz
else
    curl -L -o ${FILE_NAME}.tar.gz ${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz
fi

if [ ! -f "${FILE_NAME}.tar.gz" ]; then
    echo -e "${Red}下载失败,请检查网络连接${Font}"
    exit 1
fi

# extract and install
echo -e "${Green}解压安装中...${Font}"
tar -zxf ${FILE_NAME}.tar.gz
mkdir -p ${FRP_PATH}
mkdir -p ${BIN_PATH}
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}/
chmod +x ${FRP_PATH}/${FRP_NAME}

# ==================== 生成配置文件 ====================
echo -e "${Green}生成配置文件...${Font}"

# 基础配置
cat > ${FRP_PATH}/frps.toml << EOF
# frps 服务端配置文件
# 由安装脚本自动生成

bindPort = ${BIND_PORT}

# Dashboard 管理面板
webServer.addr = "0.0.0.0"
webServer.port = ${DASHBOARD_PORT}
webServer.user = "${DASHBOARD_USER}"
webServer.password = "${DASHBOARD_PWD}"

# Token 认证
auth.token = "${AUTH_TOKEN}"
EOF

# 可选: HTTP 代理端口
if [ -n "$VHOST_HTTP_PORT" ]; then
    echo "" >> ${FRP_PATH}/frps.toml
    echo "# HTTP 代理" >> ${FRP_PATH}/frps.toml
    echo "vhostHTTPPort = ${VHOST_HTTP_PORT}" >> ${FRP_PATH}/frps.toml
fi

# 可选: HTTPS 代理端口
if [ -n "$VHOST_HTTPS_PORT" ]; then
    echo "" >> ${FRP_PATH}/frps.toml
    echo "# HTTPS 代理" >> ${FRP_PATH}/frps.toml
    echo "vhostHTTPSPort = ${VHOST_HTTPS_PORT}" >> ${FRP_PATH}/frps.toml
fi

# 日志配置
cat >> ${FRP_PATH}/frps.toml << EOF

# 日志配置
log.to = "${FRP_PATH}/frps.log"
log.level = "info"
log.maxDays = 3
EOF

# ==================== 创建管理脚本 ====================
echo -e "${Green}创建管理脚本...${Font}"

# 主管理脚本
cat > ${FRP_PATH}/frps-manager.sh << 'MANAGEREOF'
#!/bin/sh

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[34m"
Cyan="\033[36m"
BlueBG="\033[44;37m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

FRP_PATH="${HOME}/frp"
PIDFILE="${FRP_PATH}/frps.pid"

get_status() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "running"
            return 0
        fi
    fi
    PID=$(pgrep -x frps 2>/dev/null)
    if [ -n "$PID" ]; then
        echo "$PID" > "$PIDFILE"
        echo "running"
        return 0
    fi
    echo "stopped"
    return 1
}

start_frps() {
    STATUS=$(get_status)
    if [ "$STATUS" = "running" ]; then
        echo -e "${Yellow}frps 已经在运行中 (PID: $(cat $PIDFILE))${Font}"
        return
    fi
    echo -e "${Green}正在启动 frps...${Font}"
    nohup ${FRP_PATH}/frps -c ${FRP_PATH}/frps.toml >> ${FRP_PATH}/frps.log 2>&1 &
    echo $! > "$PIDFILE"
    sleep 2
    STATUS=$(get_status)
    if [ "$STATUS" = "running" ]; then
        echo -e "${Green}frps 启动成功 (PID: $(cat $PIDFILE))${Font}"
    else
        echo -e "${Red}frps 启动失败，请查看日志: ${FRP_PATH}/frps.log${Font}"
    fi
}

stop_frps() {
    STATUS=$(get_status)
    if [ "$STATUS" = "stopped" ]; then
        echo -e "${Yellow}frps 未在运行${Font}"
        return
    fi
    echo -e "${Yellow}正在停止 frps...${Font}"
    if [ -f "$PIDFILE" ]; then
        kill $(cat "$PIDFILE") 2>/dev/null
    fi
    pkill -x frps 2>/dev/null
    rm -f "$PIDFILE"
    echo -e "${Green}frps 已停止${Font}"
}

restart_frps() {
    stop_frps
    sleep 1
    start_frps
}

show_status() {
    STATUS=$(get_status)
    echo ""
    if [ "$STATUS" = "running" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null)
        echo -e "${GreenBG} frps 状态: 运行中 ${Font}"
        echo -e "${Green}PID: ${PID}${Font}"
    else
        echo -e "${RedBG} frps 状态: 已停止 ${Font}"
    fi
}

show_config() {
    echo ""
    echo -e "${Cyan}==================== 当前配置 ====================${Font}"
    cat ${FRP_PATH}/frps.toml
    echo -e "${Cyan}==================================================${Font}"
}

show_log() {
    echo ""
    echo -e "${Cyan}==================== 最近日志 ====================${Font}"
    tail -50 ${FRP_PATH}/frps.log 2>/dev/null || echo "暂无日志"
    echo -e "${Cyan}==================================================${Font}"
}

edit_config() {
    if command -v nano >/dev/null 2>&1; then
        nano ${FRP_PATH}/frps.toml
    elif command -v ee >/dev/null 2>&1; then
        ee ${FRP_PATH}/frps.toml
    else
        vi ${FRP_PATH}/frps.toml
    fi
    echo -e "${Yellow}配置已修改，是否重启 frps? (y/n)${Font}"
    read confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        restart_frps
    fi
}

show_info() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "未知")
    BIND_PORT=$(grep "^bindPort" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' ')
    DASH_PORT=$(grep "webServer.port" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' ')
    DASH_USER=$(grep "webServer.user" ${FRP_PATH}/frps.toml | awk -F'"' '{print $2}')
    DASH_PWD=$(grep "webServer.password" ${FRP_PATH}/frps.toml | awk -F'"' '{print $2}')
    TOKEN=$(grep "auth.token" ${FRP_PATH}/frps.toml | awk -F'"' '{print $2}')
    
    echo ""
    echo -e "${Cyan}==================== 连接信息 ====================${Font}"
    echo -e "${Green}服务器地址:     ${Font}${SERVER_IP}"
    echo -e "${Green}服务端口:       ${Font}${BIND_PORT}"
    echo -e "${Green}Token:          ${Font}${TOKEN}"
    echo ""
    echo -e "${Blue}Dashboard 面板:${Font}"
    echo -e "${Green}访问地址:       ${Font}http://${SERVER_IP}:${DASH_PORT}"
    echo -e "${Green}用户名:         ${Font}${DASH_USER}"
    echo -e "${Green}密码:           ${Font}${DASH_PWD}"
    echo -e "${Cyan}==================================================${Font}"
}

uninstall_frps() {
    echo -e "${Red}警告: 这将完全卸载 frps 及所有配置!${Font}"
    printf "确认卸载? (输入 yes 继续): "
    read confirm
    if [ "$confirm" = "yes" ]; then
        stop_frps
        # remove crontab
        crontab -l 2>/dev/null | grep -v "frps" | crontab -
        # remove files
        rm -rf ${FRP_PATH}
        rm -f ${HOME}/bin/frps
        echo -e "${Green}frps 已完全卸载${Font}"
        exit 0
    else
        echo -e "${Yellow}已取消卸载${Font}"
    fi
}

show_menu() {
    clear
    echo -e "${BlueBG}                                                 ${Font}"
    echo -e "${BlueBG}           frps 服务端管理面板                   ${Font}"
    echo -e "${BlueBG}                                                 ${Font}"
    show_status
    echo ""
    echo -e "${Cyan}==================== 管理菜单 ====================${Font}"
    echo -e "${Green}1.${Font} 启动 frps"
    echo -e "${Green}2.${Font} 停止 frps"
    echo -e "${Green}3.${Font} 重启 frps"
    echo -e "${Green}4.${Font} 查看状态"
    echo -e "${Green}5.${Font} 查看日志"
    echo -e "${Green}6.${Font} 查看配置"
    echo -e "${Green}7.${Font} 编辑配置"
    echo -e "${Green}8.${Font} 连接信息"
    echo -e "${Red}9.${Font} 卸载 frps"
    echo -e "${Yellow}0.${Font} 退出"
    echo -e "${Cyan}==================================================${Font}"
    echo ""
    printf "请输入选项 [0-9]: "
}

# 直接执行命令模式
case "$1" in
    start)
        start_frps
        exit 0
        ;;
    stop)
        stop_frps
        exit 0
        ;;
    restart)
        restart_frps
        exit 0
        ;;
    status)
        show_status
        exit 0
        ;;
    log)
        tail -f ${FRP_PATH}/frps.log
        exit 0
        ;;
    info)
        show_info
        exit 0
        ;;
esac

# 菜单模式
while true; do
    show_menu
    read choice
    case "$choice" in
        1) start_frps; sleep 2 ;;
        2) stop_frps; sleep 2 ;;
        3) restart_frps; sleep 2 ;;
        4) show_status; printf "\n按回车继续..."; read dummy ;;
        5) show_log; printf "\n按回车继续..."; read dummy ;;
        6) show_config; printf "\n按回车继续..."; read dummy ;;
        7) edit_config ;;
        8) show_info; printf "\n按回车继续..."; read dummy ;;
        9) uninstall_frps ;;
        0) echo -e "${Green}再见!${Font}"; exit 0 ;;
        *) echo -e "${Red}无效选项${Font}"; sleep 1 ;;
    esac
done
MANAGEREOF
chmod +x ${FRP_PATH}/frps-manager.sh

# 创建保活脚本
cat > ${FRP_PATH}/keepalive.sh << 'KEEPALIVEEOF'
#!/bin/sh
FRP_PATH="${HOME}/frp"
PIDFILE="${FRP_PATH}/frps.pid"
LOGFILE="${FRP_PATH}/frps.log"

# check if frps is running
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
fi

# check by process name
PID=$(pgrep -x frps 2>/dev/null)
if [ -n "$PID" ]; then
    echo "$PID" > "$PIDFILE"
    exit 0
fi

# frps not running, restart it
echo "[$(date '+%Y-%m-%d %H:%M:%S')] frps 进程异常退出，正在自动重启..." >> "$LOGFILE"
nohup ${FRP_PATH}/frps -c ${FRP_PATH}/frps.toml >> "$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] frps 已重启 (PID: $!)" >> "$LOGFILE"
KEEPALIVEEOF
chmod +x ${FRP_PATH}/keepalive.sh

# 创建快捷命令
cat > ${BIN_PATH}/frps << CMDEOF
#!/bin/sh
exec ${FRP_PATH}/frps-manager.sh "\$@"
CMDEOF
chmod +x ${BIN_PATH}/frps

# ==================== 设置 crontab ====================
echo -e "${Green}设置自动保活和开机自启...${Font}"

# 添加到 crontab (保活每分钟检查，开机自启)
CRON_KEEPALIVE="* * * * * ${FRP_PATH}/keepalive.sh >/dev/null 2>&1"
CRON_REBOOT="@reboot sleep 10 && ${FRP_PATH}/keepalive.sh >/dev/null 2>&1"

# 先移除旧的 frps 相关 crontab
(crontab -l 2>/dev/null | grep -v "frps" | grep -v "keepalive"; echo "$CRON_KEEPALIVE"; echo "$CRON_REBOOT") | crontab -

# ==================== 添加 PATH ====================
# 确保 ~/bin 在 PATH 中 (兼容多种 shell)
echo -e "${Green}配置 PATH 环境变量...${Font}"

# 为各种 shell 添加 PATH 配置
# .profile - 用于 sh/bash 登录 shell
if [ ! -f "${HOME}/.profile" ]; then
    touch "${HOME}/.profile"
fi
if ! grep -q 'PATH.*\$HOME/bin' "${HOME}/.profile" 2>/dev/null; then
    echo '' >> "${HOME}/.profile"
    echo '# Added by frps installer' >> "${HOME}/.profile"
    echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.profile"
fi

# .shrc - FreeBSD 默认 shell 配置
if [ ! -f "${HOME}/.shrc" ]; then
    touch "${HOME}/.shrc"
fi
if ! grep -q 'PATH.*\$HOME/bin' "${HOME}/.shrc" 2>/dev/null; then
    echo '' >> "${HOME}/.shrc"
    echo '# Added by frps installer' >> "${HOME}/.shrc"
    echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.shrc"
fi

# .bashrc - 用于 bash
if [ -f "${HOME}/.bashrc" ]; then
    if ! grep -q 'PATH.*\$HOME/bin' "${HOME}/.bashrc" 2>/dev/null; then
        echo '' >> "${HOME}/.bashrc"
        echo '# Added by frps installer' >> "${HOME}/.bashrc"
        echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc"
    fi
fi

# .cshrc - 用于 csh/tcsh (FreeBSD 常用)
if [ ! -f "${HOME}/.cshrc" ]; then
    touch "${HOME}/.cshrc"
fi
if ! grep -q 'setenv PATH.*\$HOME/bin' "${HOME}/.cshrc" 2>/dev/null && ! grep -q 'set path.*~/bin' "${HOME}/.cshrc" 2>/dev/null; then
    echo '' >> "${HOME}/.cshrc"
    echo '# Added by frps installer' >> "${HOME}/.cshrc"
    echo 'set path = ($HOME/bin $path)' >> "${HOME}/.cshrc"
fi

# 确保当前 session 的 PATH 立即生效
export PATH="${BIN_PATH}:$PATH"

# ==================== 清理并启动 ====================
echo -e "${Green}清理临时文件...${Font}"
rm -rf ${WORK_PATH}/${FILE_NAME}.tar.gz ${WORK_PATH}/${FILE_NAME}

echo -e "${Green}启动 frps 服务...${Font}"
${FRP_PATH}/keepalive.sh
sleep 2

# ==================== 完成提示 ====================
clear
echo ""
echo -e "${GreenBG}                                                                    ${Font}"
echo -e "${GreenBG}                    frps 安装成功!                                  ${Font}"
echo -e "${GreenBG}                                                                    ${Font}"
echo ""
echo -e "${Cyan}==================== 连接信息 ====================${Font}"
echo -e "${Green}服务器地址:     ${Font}${SERVER_IP}"
echo -e "${Green}服务端口:       ${Font}${BIND_PORT}"
echo -e "${Green}Token:          ${Font}${AUTH_TOKEN}"
echo ""
echo -e "${Blue}Dashboard 管理面板:${Font}"
echo -e "${Green}访问地址:       ${Font}http://${SERVER_IP}:${DASHBOARD_PORT}"
echo -e "${Green}用户名:         ${Font}${DASHBOARD_USER}"
echo -e "${Green}密码:           ${Font}${DASHBOARD_PWD}"
echo -e "${Cyan}==================================================${Font}"
echo ""
echo -e "${Yellow}管理命令:${Font}"
echo -e "${Green}输入 ${Red}frps${Green} 进入管理面板${Font}"
echo ""
echo -e "${Yellow}快捷命令:${Font}"
echo -e "${Green}frps start   ${Font}- 启动服务"
echo -e "${Green}frps stop    ${Font}- 停止服务"
echo -e "${Green}frps restart ${Font}- 重启服务"
echo -e "${Green}frps status  ${Font}- 查看状态"
echo -e "${Green}frps log     ${Font}- 实时日志"
echo -e "${Green}frps info    ${Font}- 连接信息"
echo ""
echo -e "${Cyan}==================================================${Font}"
echo -e "${Yellow}提示: 如果 frps 命令不可用:${Font}"
echo -e "${Green}  - tcsh/csh用户请运行: ${Red}rehash${Font}"
echo -e "${Green}  - bash/sh用户请运行:  ${Red}source ~/.profile${Font}"
echo -e "${Green}  - 或者重新登录 SSH 使 PATH 生效${Font}"
echo ""
echo -e "${Green}或者直接使用完整路径: ${Red}${FRP_PATH}/frps-manager.sh${Font}"
echo -e "${Cyan}==================================================${Font}"
