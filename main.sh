#!/bin/sh

# The URL of the script project is:
# https://github.com/wy580477/replit-trojan
# https://github.com/XTLS/Xray-install

FILES_PATH=${FILES_PATH:-./}

# Gobal verbals
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
# Xray current version
CURRENT_VERSION=''

# Xray latest release version
RELEASE_LATEST=''

get_current_version() {
    # Get the CURRENT_VERSION
    if [[ -f "${FILES_PATH}/web" ]]; then
        CURRENT_VERSION="$(${FILES_PATH}/web -version | awk 'NR==1 {print $2}')"
        CURRENT_VERSION="v${CURRENT_VERSION#v}"
    else
        CURRENT_VERSION=""
    fi
}

get_latest_version() {
    # Get latest release version number
    RELEASE_LATEST="$(curl -IkLs -o ${TMP_DIRECTORY}/NUL -w %{url_effective} https://github.com/XTLS/Xray-core/releases/latest | grep -o "[^/]*$")"
    RELEASE_LATEST="v${RELEASE_LATEST#v}"
    if [[ -z "$RELEASE_LATEST" ]]; then
        echo "error: Failed to get the latest release version, please check your network."
        exit 1
    fi
}

download_xray() {
    DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/download/$RELEASE_LATEST/Xray-linux-64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
    if ! wget -qO "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    if [[ "$(cat "$ZIP_FILE".dgst)" == 'Not Found' ]]; then
        echo 'error: This version does not support verification. Please replace with another version.'
        return 1
    fi

    # Verification of Xray archive
    for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
        SUM="$(${LISTSUM}sum "$ZIP_FILE" | sed 's/ .*//')"
        CHECKSUM="$(grep ${LISTSUM^^} "$ZIP_FILE".dgst | grep "$SUM" -o -a | uniq)"
        if [[ "$SUM" != "$CHECKSUM" ]]; then
            echo 'error: Check failed! Please check your network or try again.'
            return 1
        fi
    done
}

decompression() {
    busybox unzip -q "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        "rm" -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_xray() {
    install -m 755 ${TMP_DIRECTORY}/xray ${FILES_PATH}/web
}

run_xray() {
   re_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)   
    if [ "${re_uuid}" = "" ]; then
        NEW_uuid="$(cat /proc/sys/kernel/random/uuid)"
        curl -sXPOST $REPLIT_DB_URL/re_uuid="${NEW_uuid}" 
    fi
    if [ "${uuid}" = "" ]; then
        user_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)
    else
        user_uuid=${uuid}
    fi
    cp -f ./config.yaml /tmp/config.yaml
    sed -i "s|uuid|${user_uuid}|g" /tmp/config.yaml
    ./web -c /tmp/config.yaml 2>&1 >/dev/null &
    echo
    green "当前已安装的Xray正式版本：$RELEASE_LATEST"
    echo
    UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
    v4=$(curl -s4m6 api64.ipify.org -k)
    v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`
    echo
    green "当前检测到的IP：$v4    地区：$v4l"
    echo
    yellow "vmess+ws+tls配置明文如下，相关参数可复制到客户端"
    echo "服务器地址：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "端口：443"
    echo "uuid：$user_uuid"
    echo "传输协议：ws"
    echo "host：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "path路径：/$user_uuid"
    echo "tls：开启"
    echo
replit_xray_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"replit_xray_vmess\",\
\"add\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"port\": \"443\",\
\"id\": \"$user_uuid\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"path\": \"/$user_uuid\",\
\"tls\": \"tls\"\
}"\
    | base64 -w 0)"   
yellow "分享链接如下"    
echo "${replit_xray_vmess}"
echo
yellow "二维码如下"
qrencode -t ansiutf8 ${replit_xray_vmess}
echo
green "安装完毕"
echo
echo "了解Replit，关注甬哥侃侃侃
23.1.7更新：path路径增加变量值，与uuid相同。访问域名显示为404
23.1.20更新：集成每10分钟自动唤醒功能
视频教程：https://www.youtube.com/@ygkkk
博客地址：https://ygkkk.blogspot.com"
echo
while true; do
curl https://${REPL_SLUG}.${REPL_OWNER}.repl.co;sleep 600
done
tail -f
}

# Two very important variables
TMP_DIRECTORY="$(mktemp -d)"
ZIP_FILE="${TMP_DIRECTORY}/web.zip"

get_current_version
get_latest_version
if [ "${RELEASE_LATEST}" = "${CURRENT_VERSION}" ]; then
    "rm" -rf "$TMP_DIRECTORY"
    run_xray
fi
download_xray
EXIT_CODE=$?
if [ ${EXIT_CODE} -eq 0 ]; then
    :
else
    "rm" -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    run_xray
fi
decompression "$ZIP_FILE"
install_xray
"rm" -rf "$TMP_DIRECTORY"
run_xray