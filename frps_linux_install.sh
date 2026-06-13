#!/bin/bash
# Linux frps 一键安装脚本 (NAT机/VPS 通用版)
# 交互式配置 + 自动保活 + 管理界面
# 支持 Debian/Ubuntu/CentOS/Alpine 等主流发行版

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
FRP_PATH=/usr/local/frp
BIN_PATH=/usr/local/bin
PROXY_URL="https://ghfast.top/"

# check root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${Red}错误: 请使用 root 用户运行此脚本${Font}"
        echo -e "${Yellow}请执行: sudo ./frps_linux_install.sh${Font}"
        exit 1
    fi
}

# check system
check_system() {
    if [ -f /etc/redhat-release ]; then
        SYSTEM="centos"
        PKG_MANAGER="yum"
    elif grep -qi "debian" /etc/os-release 2>/dev/null; then
        SYSTEM="debian"
        PKG_MANAGER="apt-get"
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        SYSTEM="ubuntu"
        PKG_MANAGER="apt-get"
    elif grep -qi "alpine" /etc/os-release 2>/dev/null; then
        SYSTEM="alpine"
        PKG_MANAGER="apk"
    else
        SYSTEM="unknown"
        PKG_MANAGER="apt-get"
    fi
}

# install dependencies
install_deps() {
    echo -e "${Green}检查并安装依赖...${Font}"
    if ! command -v curl &> /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            apk add --no-cache curl
        else
            $PKG_MANAGER install -y curl
        fi
    fi
    if ! command -v wget &> /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            apk add --no-cache wget
        else
            $PKG_MANAGER install -y wget
        fi
    fi
    if ! command -v openssl &> /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            apk add --no-cache openssl
        else
            $PKG_MANAGER install -y openssl
        fi
    fi
}

clear
echo -e "${BlueBG}                                                                    ${Font}"
echo -e "${BlueBG}            Linux frps 一键安装脚本 (NAT机/VPS通用)                 ${Font}"
echo -e "${BlueBG}                    交互式配置 + 自动保活                           ${Font}"
echo -e "${BlueBG}                                                                    ${Font}"
echo ""

check_root
check_system
install_deps

# check frps
if [ -f "${FRP_PATH}/${FRP_NAME}" ] || [ -f "/etc/systemd/system/${FRP_NAME}.service" ]; then
    echo -e "${Yellow}检测到已安装 frps，是否重新安装？${Font}"
    echo -e "${Red}警告: 这将删除现有配置！${Font}"
    printf "输入 y 继续，其他键退出: "
    read confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${Green}已取消安装${Font}"
        exit 0
    fi
    # stop and remove existing frps
    systemctl stop ${FRP_NAME} 2>/dev/null
    systemctl disable ${FRP_NAME} 2>/dev/null
    rm -rf ${FRP_PATH}
    rm -f /etc/systemd/system/${FRP_NAME}.service
    rm -f ${BIN_PATH}/frps-manager
    systemctl daemon-reload
fi

# ==================== 交互式配置 ====================
echo ""
echo -e "${Cyan}==================== 配置 frps 服务端 ====================${Font}"
echo ""

# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "")
if [ -z "$SERVER_IP" ]; then
    echo -e "${Yellow}无法自动获取服务器IP，请手动输入${Font}"
    printf "请输入服务器公网IP: "
    read SERVER_IP
fi
echo -e "${Green}服务器IP: ${SERVER_IP}${Font}"

# 绑定端口
echo ""
echo -e "${Yellow}请输入 frps 绑定端口 (客户端连接用)${Font}"
echo -e "${Cyan}提示: 确保防火墙已放行该端口${Font}"
printf "绑定端口 [默认 7000]: "
read BIND_PORT
BIND_PORT=${BIND_PORT:-7000}

# Dashboard 端口
echo ""
echo -e "${Yellow}请输入 Dashboard 管理面板端口${Font}"
printf "Dashboard 端口 [默认 7500]: "
read DASHBOARD_PORT
DASHBOARD_PORT=${DASHBOARD_PORT:-7500}

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
    # 生成 16 位强密码
    DASHBOARD_PWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*_+-' < /dev/urandom | head -c 16)
    echo -e "${Green}已生成强密码: ${DASHBOARD_PWD}${Font}"
fi

# Token 认证
echo ""
echo -e "${Yellow}请设置 Token (客户端连接认证密钥)${Font}"
printf "Token [留空自动生成强密钥]: "
read AUTH_TOKEN
if [ -z "$AUTH_TOKEN" ]; then
    # 生成 32 位强 Token
    AUTH_TOKEN=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*_+-' < /dev/urandom | head -c 32)
    echo -e "${Green}已生成强 Token (32位): ${AUTH_TOKEN}${Font}"
fi

# HTTP 代理端口 (可选)
echo ""
echo -e "${Yellow}HTTP 代理端口 (用于 Web 服务，可选)${Font}"
echo -e "${Cyan}如果不需要 HTTP 代理，直接回车跳过${Font}"
printf "HTTP 端口 [默认 80，留空跳过]: "
read VHOST_HTTP_PORT

# HTTPS 代理端口 (可选)
echo ""
echo -e "${Yellow}HTTPS 代理端口 (可选)${Font}"
echo -e "${Cyan}如果不需要 HTTPS 代理，直接回车跳过${Font}"
printf "HTTPS 端口 [默认 443，留空跳过]: "
read VHOST_HTTPS_PORT

# SSL/TLS 加密配置 (可选)
echo ""
echo -e "${Yellow}是否启用 SSL/TLS 加密功能 (配合 CDN 回源等场景)?${Font}"
printf "启用 SSL/TLS? (y/n) [默认 n]: "
read ENABLE_SSL
ENABLE_SSL=${ENABLE_SSL:-n}

if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
    echo ""
    echo -e "${Yellow}请选择证书来源:${Font}"
    echo "  1) 使用自签证书 (自动生成)"
    echo "  2) 使用已有证书 (手动提供路径)"
    printf "输入选项 [默认 1]: "
    read SSL_TYPE
    SSL_TYPE=${SSL_TYPE:-1}

    if [ "$SSL_TYPE" = "1" ]; then
        echo ""
        printf "请输入自签证书的域名或公网IP [默认 ${SERVER_IP}]: "
        read SSL_DOMAIN
        SSL_DOMAIN=${SSL_DOMAIN:-${SERVER_IP}}
        
        GENERATE_SELF_SIGNED="true"
        CERT_FILE="${FRP_PATH}/cert.pem"
        KEY_FILE="${FRP_PATH}/key.pem"
    else
        echo ""
        printf "请输入证书 cert.pem 的绝对路径: "
        read CERT_FILE
        while [ ! -f "$CERT_FILE" ]; do
            echo -e "${Red}文件不存在: ${CERT_FILE}${Font}"
            printf "请重新输入证书 cert.pem 的绝对路径: "
            read CERT_FILE
        done

        printf "请输入密钥 key.pem 的绝对路径: "
        read KEY_FILE
        while [ ! -f "$KEY_FILE" ]; do
            echo -e "${Red}文件不存在: ${KEY_FILE}${Font}"
            printf "请重新输入密钥 key.pem 的绝对路径: "
            read KEY_FILE
        done
        GENERATE_SELF_SIGNED="false"
    fi
else
    ENABLE_SSL="n"
fi

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
if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
    echo -e "${Green}SSL/TLS 加密:     ${Font}已启用"
    if [ "$GENERATE_SELF_SIGNED" = "true" ]; then
        echo -e "${Green}证书类型:         ${Font}自签证书 (证书域名: ${SSL_DOMAIN})"
    else
        echo -e "${Green}证书类型:         ${Font}自定义证书"
        echo -e "${Green}证书路径:         ${Font}${CERT_FILE}"
        echo -e "${Green}密钥路径:         ${Font}${KEY_FILE}"
    fi
else
    echo -e "${Green}SSL/TLS 加密:     ${Font}未启用"
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
    armv7l|armv7)
        PLATFORM=arm
        ;;
    *)
        echo -e "${Red}不支持的系统架构: ${ARCH}${Font}"
        exit 1
        ;;
esac

FILE_NAME=frp_${FRP_VERSION}_linux_${PLATFORM}
echo -e "${Green}系统: ${SYSTEM} | 架构: ${PLATFORM}${Font}"

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
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}/
chmod +x ${FRP_PATH}/${FRP_NAME}

# 生成自签证书
if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
    if [ "$GENERATE_SELF_SIGNED" = "true" ]; then
        echo -e "${Green}生成自签证书中...${Font}"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout "${KEY_FILE}" -out "${CERT_FILE}" -subj "/CN=${SSL_DOMAIN}" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${Green}自签证书生成成功!${Font}"
        else
            echo -e "${Red}错误: 自签证书生成失败，请检查 openssl 是否工作正常。${Font}"
            exit 1
        fi
    fi
fi

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

# SSL/TLS 配置
if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
    cat >> ${FRP_PATH}/frps.toml << EOF

# SSL/TLS 加密配置
transport.tls.certFile = "${CERT_FILE}"
transport.tls.keyFile = "${KEY_FILE}"
EOF
fi

# ==================== 创建 systemd 服务 ====================
echo -e "${Green}创建 systemd 服务...${Font}"

cat > /etc/systemd/system/frps.service << EOF
[Unit]
Description=frp Server Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=${FRP_PATH}/frps -c ${FRP_PATH}/frps.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# ==================== 创建管理脚本 ====================
echo -e "${Green}创建管理脚本...${Font}"

cat > ${BIN_PATH}/frps-manager << 'MANAGEREOF'
#!/bin/bash

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

FRP_PATH="/usr/local/frp"

get_status() {
    if systemctl is-active --quiet frps; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

start_frps() {
    STATUS=$(get_status)
    if [ "$STATUS" = "running" ]; then
        echo -e "${Yellow}frps 已经在运行中${Font}"
        return
    fi
    echo -e "${Green}正在启动 frps...${Font}"
    systemctl start frps
    sleep 2
    STATUS=$(get_status)
    if [ "$STATUS" = "running" ]; then
        echo -e "${Green}frps 启动成功${Font}"
    else
        echo -e "${Red}frps 启动失败，请查看日志: journalctl -u frps${Font}"
    fi
}

stop_frps() {
    STATUS=$(get_status)
    if [ "$STATUS" = "stopped" ]; then
        echo -e "${Yellow}frps 未在运行${Font}"
        return
    fi
    echo -e "${Yellow}正在停止 frps...${Font}"
    systemctl stop frps
    echo -e "${Green}frps 已停止${Font}"
}

restart_frps() {
    echo -e "${Yellow}正在重启 frps...${Font}"
    systemctl restart frps
    sleep 2
    STATUS=$(get_status)
    if [ "$STATUS" = "running" ]; then
        echo -e "${Green}frps 重启成功${Font}"
    else
        echo -e "${Red}frps 重启失败${Font}"
    fi
}

show_status() {
    STATUS=$(get_status)
    echo ""
    if [ "$STATUS" = "running" ]; then
        PID=$(pgrep -x frps)
        echo -e "${GreenBG} frps 状态: 运行中 ${Font}"
        echo -e "${Green}PID: ${PID}${Font}"
        # 显示运行时间
        UPTIME=$(systemctl show frps --property=ActiveEnterTimestamp --value)
        echo -e "${Green}启动时间: ${UPTIME}${Font}"
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
    if [ -f "${FRP_PATH}/frps.log" ]; then
        tail -50 ${FRP_PATH}/frps.log
    else
        journalctl -u frps -n 50 --no-pager
    fi
    echo -e "${Cyan}==================================================${Font}"
}

edit_config() {
    if command -v nano &> /dev/null; then
        nano ${FRP_PATH}/frps.toml
    elif command -v vim &> /dev/null; then
        vim ${FRP_PATH}/frps.toml
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
    SSL_CERT=$(grep "transport.tls.certFile" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' "' 2>/dev/null)
    
    echo ""
    echo -e "${Cyan}==================== 连接信息 ====================${Font}"
    echo -e "${Green}服务器地址:     ${Font}${SERVER_IP}"
    echo -e "${Green}服务端口:       ${Font}${BIND_PORT}"
    echo -e "${Green}Token:          ${Font}${TOKEN}"
    if [ -n "$SSL_CERT" ]; then
        SSL_KEY=$(grep "transport.tls.keyFile" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' "' 2>/dev/null)
        echo -e "${Green}SSL/TLS 加密:   ${Font}已启用"
        echo -e "${Green}证书路径:       ${Font}${SSL_CERT}"
        echo -e "${Green}密钥路径:       ${Font}${SSL_KEY}"
    else
        echo -e "${Green}SSL/TLS 加密:   ${Font}未启用"
    fi
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
        systemctl stop frps
        systemctl disable frps
        rm -rf ${FRP_PATH}
        rm -f /etc/systemd/system/frps.service
        rm -f /usr/local/bin/frps-manager
        systemctl daemon-reload
        echo -e "${Green}frps 已完全卸载${Font}"
        exit 0
    else
        echo -e "${Yellow}已取消卸载${Font}"
    fi
}

open_firewall() {
    BIND_PORT=$(grep "^bindPort" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' ')
    DASH_PORT=$(grep "webServer.port" ${FRP_PATH}/frps.toml | awk -F'=' '{print $2}' | tr -d ' ')
    
    echo -e "${Yellow}正在配置防火墙...${Font}"
    
    # 检测防火墙类型并开放端口
    if command -v firewall-cmd &> /dev/null; then
        # firewalld (CentOS/RHEL)
        firewall-cmd --permanent --add-port=${BIND_PORT}/tcp
        firewall-cmd --permanent --add-port=${DASH_PORT}/tcp
        firewall-cmd --reload
        echo -e "${Green}firewalld 已放行端口 ${BIND_PORT}, ${DASH_PORT}${Font}"
    elif command -v ufw &> /dev/null; then
        # ufw (Ubuntu/Debian)
        ufw allow ${BIND_PORT}/tcp
        ufw allow ${DASH_PORT}/tcp
        echo -e "${Green}ufw 已放行端口 ${BIND_PORT}, ${DASH_PORT}${Font}"
    elif command -v iptables &> /dev/null; then
        # iptables
        iptables -A INPUT -p tcp --dport ${BIND_PORT} -j ACCEPT
        iptables -A INPUT -p tcp --dport ${DASH_PORT} -j ACCEPT
        echo -e "${Green}iptables 已放行端口 ${BIND_PORT}, ${DASH_PORT}${Font}"
    else
        echo -e "${Yellow}未检测到防火墙，请手动放行端口${Font}"
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
    echo -e "${Green}9.${Font} 放行防火墙"
    echo -e "${Red}10.${Font} 卸载 frps"
    echo -e "${Yellow}0.${Font} 退出"
    echo -e "${Cyan}==================================================${Font}"
    echo ""
    printf "请输入选项 [0-10]: "
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
        tail -f ${FRP_PATH}/frps.log 2>/dev/null || journalctl -u frps -f
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
        9) open_firewall; printf "\n按回车继续..."; read dummy ;;
        10) uninstall_frps ;;
        0) echo -e "${Green}再见!${Font}"; exit 0 ;;
        *) echo -e "${Red}无效选项${Font}"; sleep 1 ;;
    esac
done
MANAGEREOF

chmod +x ${BIN_PATH}/frps-manager

# 创建 frps 快捷命令
ln -sf ${BIN_PATH}/frps-manager ${BIN_PATH}/frps 2>/dev/null || cp ${BIN_PATH}/frps-manager ${BIN_PATH}/frps

# ==================== 启动服务 ====================
echo -e "${Green}启动 frps 服务...${Font}"
systemctl daemon-reload
systemctl enable frps
systemctl start frps
sleep 2

# ==================== 配置防火墙 ====================
echo -e "${Green}配置防火墙...${Font}"
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${BIND_PORT}/tcp 2>/dev/null
    firewall-cmd --permanent --add-port=${DASHBOARD_PORT}/tcp 2>/dev/null
    firewall-cmd --reload 2>/dev/null
elif command -v ufw &> /dev/null; then
    ufw allow ${BIND_PORT}/tcp 2>/dev/null
    ufw allow ${DASHBOARD_PORT}/tcp 2>/dev/null
fi

# ==================== 清理 ====================
echo -e "${Green}清理临时文件...${Font}"
rm -rf ${WORK_PATH}/${FILE_NAME}.tar.gz ${WORK_PATH}/${FILE_NAME}

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
if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
    echo -e "${Green}SSL/TLS 加密:   ${Font}已启用"
    echo -e "${Green}证书路径:       ${Font}${CERT_FILE}"
    echo -e "${Green}密钥路径:       ${Font}${KEY_FILE}"
fi
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
echo -e "${Yellow}systemctl 命令:${Font}"
echo -e "${Green}systemctl status frps  ${Font}- 查看状态"
echo -e "${Green}systemctl restart frps ${Font}- 重启服务"
echo -e "${Cyan}==================================================${Font}"
