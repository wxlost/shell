#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: Caddy Install
#       Version: 0.0.8
#       Author: onepvp.com
#       Web: https://onepvp.com
#=================================================
file="/usr/local/caddy/"
caddy_file="/usr/local/caddy/caddy"
caddy_conf_file="/usr/local/caddy/Caddyfile"
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${caddy_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 没有安装，请检查 !" && exit 1
}
Download_caddy(){
	[[ ! -e ${file} ]] && mkdir "${file}"
	cd "${file}"
	PID=$(ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_onepvp" |awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
	[[ -e "caddy_linux*.tar.gz" ]] && rm -rf "caddy_linux*.tar.gz"
	[[ ! -z ${extension} ]] && extension_all="?plugins=${extension}"
	if [[ ${bit} == "i386" ]]; then
		wget -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/386${extension_all}" && caddy_bit="caddy_linux_386"
	elif [[ ${bit} == "i686" ]]; then
		wget -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/386${extension_all}" && caddy_bit="caddy_linux_386"
	elif [[ ${bit} == "x86_64" ]]; then
		wget -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/amd64${extension_all}" && caddy_bit="caddy_linux_amd64"
	else
		echo -e "${Error_font_prefix}[错误]${Font_suffix} 不支持 ${bit} !" && exit 1
	fi
	[[ ! -e "caddy_linux.tar.gz" ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 下载失败 !" && exit 1
	tar zxf "caddy_linux.tar.gz"
	rm -rf "caddy_linux.tar.gz"
	[[ ! -e ${caddy_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 解压失败或压缩文件错误 !" && exit 1
	rm -rf LICENSES.txt
	rm -rf README.txt 
	rm -rf CHANGES.txt
	rm -rf "init/"
	chmod +x caddy
}
Service_caddy(){
	if [[ ${release} = "centos" ]]; then
		if ! wget https://raw.githubusercontent.com/wxlost/shell/master/caddy/other/caddy_centos -O /etc/init.d/caddy; then
			echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/caddy
		chkconfig --add caddy
		chkconfig caddy on
	else
		if ! wget https://raw.githubusercontent.com/wxlost/shell/master/caddy/other/caddy_debian -O /etc/init.d/caddy; then
			echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi
}
install_caddy(){
	if [[ -e ${caddy_file} ]]; then
		echo && echo -e "${Error_font_prefix}[信息]${Font_suffix} 检测到 Caddy 已安装，是否继续安装(覆盖更新)？[y/N]"
		stty erase '^H' && read -p "(默认: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			55_caddy
			echo && echo "已取消覆盖安装Caddy..." && exit 1
		fi
	fi
	Download_caddy
	Service_caddy
	55_caddy
	echo && echo -e " Caddy 配置文件：${caddy_conf_file} \n 使用说明：service caddy start | stop | restart | status \n ${Info_font_prefix}[信息]${Font_suffix} Caddy 安装完成！" && echo
}
uninstall_caddy(){
	check_installed_status
	echo && echo "确定要卸载 Caddy ? [y/N]"
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_onepvp" |awk '{print $2}'`
		[[ ! -z ${PID} ]] && kill -9 ${PID}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del caddy
		else
			update-rc.d -f caddy remove
		fi
		rm -rf ${caddy_file}
		rm -rf ${caddy_conf_file}
		rm -rf /etc/init.d/caddy
		[[ ! -e ${caddy_file} ]] && echo && echo -e "${Info_font_prefix}[信息]${Font_suffix} Caddy 卸载完成 !" && echo && exit 1
		echo && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 卸载失败 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
55_caddy(){
#注意.个人自用.使用前请仔细修改自己需要的参数
#随机国外网站 暂定为各个学校
	if [[ -e /home/shadowsocks/user-config.json ]]; then
		echo && echo -e "${Error_font_prefix}[信息]${Font_suffix} 检测到 55R 已安装，是否继续安装对应配置(覆盖更新)？[y/N]"
		stty erase '^H' && read -p "(默认: y):" yn
		[[ -z ${yn} ]] && yn="y"
		if [[ ${yn} == [Nn] ]]; then
			echo && echo "已取消..." && exit 1
		fi
	fi

Sch1="ocw.mit.edu"
Sch2="www.seas.harvard.edu"
Sch3="www.harvard.edu"
Sch3="www.cornell.edu"
Sch4="www.stanford.edu"
Sch5="www.yale.edu"
Sch6="www.cmu.edu"
Sch7="www.columbia.edu"
Sch8="www.caltech.edu"
Sch9="www.umich.edu"
jw=($Sch1 $Sch2 $Sch3 $Sch4 $Sch5 $Sch6 $Sch7 $Sch8 $Sch9)
i=0
while [ $i -lt 1 ];do
    a=$(( $RANDOM % 9 ))
    School=${jw[$a]}
    echo $School
    i=$(( $i + 1 ))
done
#随机完成

    while true
    do
  NODE_ID=$(grep ^NODE_ID /home/shadowsocks/userapiconfig.py | awk '{print $3}')
  echo -e "${CBLUE}当前节点: ${Info_font_prefix}${NODE_ID}${Font_suffix}"
    echo -e "请输入上面的ID: [3-65535]:"
    read -p "(默认ID: ${NODE_ID}):" webid
    [ -z "${webid}" ] && webid=${NODE_ID}
    expr ${webid} + 0 &>/dev/null
            echo
            echo "---------------------------"
            echo -e "当前输入节点ID = ${Info_font_prefix}[${webid}]${Font_suffix}"
            echo "---------------------------"
            echo
            break
    done
    echo

echo "https://vps${webid}.onepve.com:1433 {
 gzip
 tls noreply@onehero.xyz
 proxy / https://${School}
}
:1433 {
 gzip
 tls noreply@onehero.xyz
 proxy / https://${School}
}" > /usr/local/caddy/Caddyfile

	if ! wget https://raw.githubusercontent.com/wxlost/shell/master/caddy/other/user-config.json -O /home/shadowsocks/user-config.json; then
		echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
	fi
	
	echo && echo -e " 55r 配置文件：/home/shadowsocks/user-config.json \n [信息]redirect 配置完成！" && echo
	
if [ "${release}" == 'centOS' ]; then
	service supervisord restart
else
	supervisorctl restart ssr
fi
}

check_sys
action=$1
extension=$2
[[ -z $1 ]] && action=install
case "$action" in
    install|uninstall|55)
    ${action}_caddy
    ;;
    *)
    echo "输入错误 !"
    echo "用法: {install | uninstall | 55}"
    ;;
esac