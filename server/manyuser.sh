#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear

# get pwd
sed -i "s@^oneinstack_dir.*@oneinstack_dir=$(pwd)@" ./options.conf

#mkdir src
if [ ! -d `pwd`/include ]; then
  mkdir include
fi
if [ ! -d `pwd`/src ]; then
  mkdir src
fi
pushd src > /dev/null
. ../options.conf
. ../include/color.sh
. ../include/check_os.sh
. ../include/download.sh
. ../include/python.sh

Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

# Check if user is root
[ $(id -u) != '0' ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

[ "${CentOS_RHEL_version}" == '5' ] && { echo "${CWARNING}SS only support CentOS6,7 or Debian or Ubuntu! ${CEND}"; exit 1; }
#从github自动获取libsodium的最新版版本号
git_crypto_versions(){
	#crypto=$(wget -qO- https://github.com/jedisct1/libsodium/releases/latest | grep "<title>" |sed -r 's/.*Release (.+) · jedisct1.*/\1/')
  crypto="1.0.16"
}
#配置后端对接节点ID
id_install(){
    while true
    do
    echo -e "${CBLUE}当前系统为: ${OS} ${CentOS_RHEL_version}${CEND}"
    echo "请输入新节点ID: [0,3-65535]:"
    read -p "(默认ID: 3):" webid
    [ -z "${webid}" ] && webid="3"
    expr ${webid} + 0 &>/dev/null
    if [ ${webid} -ge 3 ] && [ ${webid} -le 65535 ] && [ ${webid} -ne 2 ] && [ ${webid} -ne 3 ]; then
        echo
        echo "---------------------------"
        if [ ${webid} -eq 0 ]; then
        echo -e "当前输入节点ID = ${Info_font_prefix}[${webid}][自动模式]${Font_suffix}"
        else
        echo -e "当前输入节点ID = ${Info_font_prefix}[${webid}]${Font_suffix}"
        fi
        echo "---------------------------"
        echo
        break
    else
        echo "${CWARNING}2输入错误，请输入正确的数字!${CEND}"
    fi
    done
    echo
    read -p "按任意键继续安装...按Ctrl + C取消" var
    
}

#防火墙10000:65535
Iptables_set() {
 [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
  echo "${CBLUE}当前ssh端口: ${ssh_port}${CEND}"
# check iptables
iptables_yn=n
		if [ "${OS}" = "CentOS" ]; then
		chkconfig iptables off 2>/dev/null && service iptables stop 2>/dev/null
		systemctl disable firewalld 2>/dev/null && systemctl stop firewalld 2>/dev/null
		echo  "Info: ${OS} 防火墙关闭并禁止自启动（老手自理）"
		else
		echo  "Info: ${OS} 防火墙默认没安装，故此没有判断（老手自理）"
		fi
    
# init
startTime=`date +%s`
. ../include/memory.sh
case "${OS}" in
  "CentOS")
    . ../include/init_CentOS.sh 2>&1 | tee -a ${oneinstack_dir}/src/install.log
    [ -n "$(gcc --version | head -n1 | grep '4\.1\.')" ] && export CC="gcc44" CXX="g++44"
    ;;
  "Debian")
    . ../include/init_Debian.sh 2>&1 | tee -a ${oneinstack_dir}/src/install.log
    ;;
  "Ubuntu")
    . ../include/init_Ubuntu.sh 2>&1 | tee -a ${oneinstack_dir}/src/install.log
    ;;
esac
}
#安装第一步
Def_parameter() {
  if [ "${OS}" == "CentOS" ]; then
    id_install
    pkgList="wget unzip nss curl libcurl openssl-devel gcc swig autoconf libtool libevent automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel git asciidoc xmlto pcre-devel mbedtls-devel udns-devel libev-devel libsodium"
    for Package in ${pkgList}; do
      yum -y install ${Package}
    done
    Iptables_set
  else
    id_install
    apt-get -y update && apt-get upgrade -y
    pkgList="curl wget unzip gcc swig automake autoconf make libtool perl cpio git libmbedtls-dev libudns-dev libev-dev"
    for Package in ${pkgList}; do
      apt-get -y install $Package
    done
    Iptables_set
  fi
}

#下载安装libsodium
download_files_libsodium(){
  git_crypto_versions
  #src_url=https://github.com/jedisct1/libsodium/releases/download/${crypto}/libsodium-${crypto}.tar.gz && Download_src
  src_url=https://raw.githubusercontent.com/wxlost/shell/master/server/src/libsodium-${crypto}.tar.gz && Download_src
  tar zxf libsodium-${crypto}.tar.gz
  pushd libsodium-${crypto}
  ./configure
  make -j ${THREAD} && make install
  popd
  rm -rf libsodium-${crypto}
  if [ $? -ne 0 ]; then
     echo "${CWARNING}libsodium 安装失败!${CEND}"
     exit 1
  fi
  echo "${CBLUE}libsodium 安装成功!${CEND}"
  echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
  ldconfig
}
#manyuser
Install_SSR-python() {
  pushd /usr/bin
  rm -rf /usr/bin/caddy
  src_url=https://raw.githubusercontent.com/wxlost/shell/master/server/src/caddy.zip && Download_src
  unzip caddy.zip
  rm -rf /usr/bin/caddy.zip
  popd
  if [ ! -f /usr/bin/caddy/server.py ]; then
    echo "${CWARNING}魔改后端下载失败!${CEND}"
    exit 1
  else
    pushd /usr/bin/caddy
    cp apiconfig.py userapiconfig.py
    cp config.json user-config.json
    cp detect.html user-detect.html
    ${python_install_dir}/bin/pip install -r requirements.txt
    popd
    echo "${CBLUE}魔改后端安装成功!${CEND}"
    config_userapiconfig
  fi
}
# 设置55R后端节点
config_userapiconfig(){
    #先删除缓存
    rm -rf /usr/bin/caddy/*.pyc
    #写出配置
    cat > /usr/bin/caddy/userapiconfig.py<<-EOF
# Config
NODE_ID = ${webid}


# hour,set 0 to disable
SPEEDTEST = ${speed}
CLOUDSAFE = 1
ANTISSATTACK = 0
AUTOEXEC = 0

MU_SUFFIX = '${MU_SUFFIX}'
MU_REGEX = '%5m%id.%suffix'

SERVER_PUB_ADDR = '127.0.0.1'  # mujson_mgr need this to generate ssr link
API_INTERFACE = 'modwebapi'  # glzjinmod, modwebapi

WEBAPI_URL = '${weburl}'
WEBAPI_TOKEN = '${webtoken}'

# mudb
MUDB_FILE = 'mudb.json'

# Mysql
MYSQL_HOST = '127.0.0.1'
MYSQL_PORT = 3306
MYSQL_USER = 'ss'
MYSQL_PASS = 'ss'
MYSQL_DB = 'shadowsocks'

MYSQL_SSL_ENABLE = 0
MYSQL_SSL_CA = ''
MYSQL_SSL_CERT = ''
MYSQL_SSL_KEY = ''

# API
API_HOST = '127.0.0.1'
API_PORT = 80
API_PATH = '/mu/v2/'
API_TOKEN = 'abcdef'
API_UPDATE_TIME = 60

# Manager (ignore this)
MANAGE_PASS = 'ss233333333'
# if you want manage in other server you should set this value to global ip
MANAGE_BIND_IP = '127.0.0.1'
# make sure this port is idle
MANAGE_PORT = 23333

# Safety
IP_MD5_SALT = 'randomforsafety'

EOF
echo "${CBLUE}魔改后端配置写入完毕${CEND}"
config_hosts
}

#配置 hosts
config_hosts(){

	if [ ${hosts} -ne 0 ]; then
		echo "${CBLUE}配置Hosts文件绕过CDN${CEND}"
		if [ ! -f "/etc/hosts.backup" ]; then
			#备份不存在-备份一份
			cp /etc/hosts /etc/hosts.backup
		else
			#备份存在-还原纯净备份
			rm -rf /etc/hosts
			cp -f /etc/hosts.backup /etc/hosts
		fi
	#写hosts
	echo -e "\n${hostsip} ${hostsurl}" >> /etc/hosts
	fi
}
#进程守护 Supervisor
#/usr/local/python/bin/python -V
config_supervisord(){
  if [ "${OS}" == 'CentOS' ]; then
  #CentOS 6
  yum install epel* -y
  #----------------
  yum -y install supervisor
    sed -i 's@pidfile=/tmp/supervisord.pid@pidfile=/var/run/supervisord.pid@' /etc/supervisord.conf
    [ -z "$(grep 'program:caddy' /etc/supervisord.conf)" ] && cat >> /etc/supervisord.conf << EOF
[program:caddy]
command=${python_install_dir}/bin/python /usr/bin/caddy/server.py
startretries=36
EOF
    chkconfig supervisord on
    service supervisord stop
  echo -e "${CBLUE}${OS} 进程守护 supervisord 配置完毕${CEND}"
  else
  apt-get install supervisor -y
  #----------------
    sed -i 's@pidfile=/tmp/supervisord.pid@pidfile=/var/run/supervisord.pid@' /etc/supervisor/supervisord.conf
    [ -z "$(grep 'program:caddy' /etc/supervisor/supervisord.conf)" ] && cat >> /etc/supervisor/supervisord.conf << EOF
[program:caddy]
command=${python_install_dir}/bin/python /usr/bin/caddy/server.py
startretries=36
EOF
    supervisorctl update
    supervisorctl stop caddy
  echo -e "${CBLUE}${OS} 进程守护 supervisord 配置完毕${CEND}"
  fi
}
Uninstall_SS() {
  while :; do echo
    read -p "Do you want to uninstall SS? [y/n]: " SS_yn
    if [[ ! "${SS_yn}" =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done

  if [ "${SS_yn}" == 'y' ]; then
    echo "卸载功能未做!"
  fi
}

Print_User_SS() {
  pushd ${oneinstack_dir}
if [ "${OS}" == 'CentOS' ]; then
	service supervisord restart
else
	supervisorctl restart caddy
fi
  clear
  echo ""
  echo "后端安装成功!"
  echo ""
  if [ ${webid} -eq 0 ]; then
  echo -e "服务器ID: ${Info_font_prefix}[自动模式]${Font_suffix}"
  else
  echo -e "服务器ID: ${Info_font_prefix}[${webid}]${Font_suffix}"
  fi
  echo ""
if [ "${OS}" == 'CentOS' ]; then
	curl ${weburl}/mod_mu/func/ping?key=${webtoken}
else
	curl --insecure ${weburl}/mod_mu/func/ping?key=${webtoken}
fi
  echo ""
  echo -e "出现 ${Info_font_prefix}[pong]${Font_suffix} 即为成功!"
	echo ""
  if [ ${hosts} -ne 0 ]; then
	echo "----------hosts-----------"
	grep ^${hostsip} /etc/hosts
	echo "----------end-----------"
  fi
	echo -e "\n"
}
#/usr/local/python//bin/python
case "$1" in
install)
  Def_parameter
  #[ ! -e "${python_install_dir}/bin/python" ] && Install_Python
  Install_Python
  download_files_libsodium
  Install_SSR-python
  config_supervisord
  Print_User_SS
  echo -e "libsodium\t${crypto}" > /usr/bin/caddy/versions.txt
  ;;
upconfig)
  git_crypto_versions
  NODE_ID=$(grep ^NODE_ID /usr/bin/caddy/userapiconfig.py | awk '{print $3}')
  echo -e "${CBLUE}当前节点: ${NODE_ID}  当前加密库版本${crypto}${CEND}"
  id_install
  config_userapiconfig
#----------------  
  if [ -e "/usr/bin/caddy/versions.txt" ]; then
  crypto_new_ver=$(grep ^libsodium /usr/bin/caddy/versions.txt | awk '{print $2}')
    if [[ ${crypto_new_ver} != ${crypto} ]]; then
      download_files_libsodium
      echo -e "libsodium\t${crypto}" > /usr/bin/caddy/versions.txt
    fi
  else
    touch /usr/bin/caddy/versions.txt
  fi
#----------------
  Print_User_SS
  ;;
uninstall)
  #Check_SS
  #Uninstall_SS
  ;;
*)
  echo
  echo "Usage: ${CMSG}$0${CEND} { ${CMSG}install${CEND} | ${CMSG}upconfig${CEND} | ${CMSG}uninstall${CEND} }"
  echo
  exit 1
esac
