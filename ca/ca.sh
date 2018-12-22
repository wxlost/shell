#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH
#Version: 0.6.8

govar="0.2.4"

#这里判断系统
if [ -f /etc/redhat-release ]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
fi

[[ $EUID -ne 0 ]] && echo -e "Error: This script must be run as root!" && exit 1

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
	[[ -z ${IP} ]] && IP=$( wget -qO- -t1 -T2 myip.ipip.net )
    [[ -z ${IP} ]] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [[ -z ${IP} ]] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
#	clear
    [[ ! -z ${IP} ]] && echo 网卡 IP：${IP} && echo $ipname || echo "-------------------"
}

# Install some dependencies
clear

printf "
#######################################################################
#     欢迎使用 SSH密钥安装程序 ${govar}
#     系统支持 CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#######################################################################
"
#read -p "按任意键继续...按 Ctrl + C 取消" var

#check count of parameters. We need only 1, which is key id
if [ $# -eq 0 -o $# -gt 2 ]; then
	echo "Info: 欢迎使用SSH密钥安装程序!"
	echo " - Usage: $0 {http} [-p]"; exit 1;
fi
KEY_ID=${1}
DISABLE_PW_LOGIN=0
authorized_keys=1
SHELL_ZZH=0
rm -rf /tmp/key.txt
rm -rf /tmp/headers.txt
if [ $# -eq 2 -a "$2" = '-p' ]; then
	DISABLE_PW_LOGIN=1
fi

# Disable selinux
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi

echo -e "Info: 是否安装可能需要的依赖[Y/n]"
read -p "(默认: y):" yn
[[ -z "${yn}" ]] && yn="y"
if [[ ${yn} == [Yy] ]]; then
	if [ "${release}" = "centos" ]; then
		#yum -y upgrade
		yum install epel* -y
		#yum -y remove ntp
    	pkgList="iftop htop wget vim net-tools git unzip ca-certificates"
    	for Package in ${pkgList}; do
    		yum -y install ${Package}
    	done
	else
		apt-get update -y
		#apt-get upgrade -y
    	pkgList="iftop htop wget curl vim net-tools git unzip ca-certificates"
    	for Package in ${pkgList}; do
      		apt-get -y install $Package
    	done
	fi
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	clear
fi

if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
	echo "Info: ~/.ssh/authorized_keys is missing ...";

	echo "Creating ${HOME}/.ssh/authorized_keys ..."
	mkdir -p ${HOME}/.ssh/
	touch ${HOME}/.ssh/authorized_keys

	if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
		echo "Info: 无法创建SSH密钥文件!"
	else
		echo "Info: 密钥文件已创建，正在进行下一步..."
	fi
fi

curl --insecure -D /tmp/headers.txt ${KEY_ID} >/tmp/key.txt 2>/dev/null
HTTP_CODE=$(sed -n 's/HTTP\/1\.[0-9] \([0-9]\+\).*/\1/p' /tmp/headers.txt | tail -n 1)
PUB_KEY="$(cat /tmp/key.txt)"
HTTP_CODE="${HTTP_CODE// /}"

echo "--------$HTTP_CODE--------"
if [[ $HTTP_CODE -ne 200 ]]; then
	if [ -z "`grep ^ssh-rsa /tmp/key.txt`" ]; then
		echo &&	echo -e "Error: 密钥下载失败!($HTTP_CODE)" && echo && echo "------/tmp/headers.txt----↓---" && cat /tmp/headers.txt && echo "------/tmp/key.txt----↓---" && cat /tmp/key.txt && echo "------Error--log----↑-------------" && echo "Info: 然后截图内容反馈!" && exit 1;
	fi
fi

if [ "${PUB_KEY}" = '0' ]; then
	echo "Error: Key ${KEY_ID} wasn't found on Key Manager"; exit 1;
fi

if [ $(grep -m 1 -c "${PUB_KEY}" ${HOME}/.ssh/authorized_keys) -eq 1 ]; then
	echo -e "Info: 发现密钥已经安装，是否更新？[Y/n]"
	read -p "(默认: y):" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ ${yn} == [Nn] ]]; then
		authorized_keys=0
		echo && echo "Info: 已取消更新安装密钥..." && echo
	else
	rm -rf ${HOME}/.ssh/authorized_keys && touch ${HOME}/.ssh/authorized_keys
	fi
fi

#install key
if [ ${authorized_keys} -eq 1 ]; then
	#echo -e "\n${PUB_KEY}\n" >> ${HOME}/.ssh/authorized_keys
	echo -e "${PUB_KEY}\n" >> ${HOME}/.ssh/authorized_keys
	if [ -z "`grep ^ssh-rsa ${HOME}/.ssh/authorized_keys`" ]; then
		rm -rf ${HOME}/.ssh/authorized_keys && touch ${HOME}/.ssh/authorized_keys
		echo &&	echo "Error: 钥匙安装失败!($Verif)" && echo && echo "-----${HOME}/.ssh/authorized_keys---↓---" && echo "$var" && echo "------var-------↓---" && echo "$PUB_KEY" && echo "------Error--log----↑-------------" && echo "Info: 然后截图内容反馈!" && exit 1;
	fi
	rm -rf /tmp/key.txt
	rm -rf /tmp/headers.txt
	chmod 700 ${HOME}/.ssh
	chmod 600 ${HOME}/.ssh/authorized_keys
	echo 'Info: 钥匙安装成功!'

#disable root password
if [ ${DISABLE_PW_LOGIN} -eq 1 ]; then
	#grep ^PasswordAuthentication /etc/ssh/sshd_config | awk '{print $2}'
	if [ -z "`grep ^PasswordAuthentication /etc/ssh/sshd_config`" ]; then
	sed -i "s@^#PasswordAuthentication.*@&\nPasswordAuthentication no@" /etc/ssh/sshd_config
	else
	sed -i "s@^PasswordAuthentication.*@PasswordAuthentication no@" /etc/ssh/sshd_config
	fi
	echo 'Info: 禁用密码登录设置完毕!'
	#echo 'Restart SSHd manually!'
fi

if [ ${DISABLE_PW_LOGIN} -eq 1 ]; then
	#grep ^StrictModes /etc/ssh/sshd_config | awk '{print $2}'
	if [ -z "`grep ^StrictModes /etc/ssh/sshd_config`" ]; then
		sed -i "s@^#StrictModes.*@&\nStrictModes no@" /etc/ssh/sshd_config
	else
		sed -i "s@^StrictModes.*@StrictModes no@" /etc/ssh/sshd_config
	fi
	echo 'Info: 关闭StrictModes设置完毕!'
	#echo 'Restart SSHd manually!'
fi

if [ "${release}" = 'centos' ]; then
	service sshd restart
else
	/etc/init.d/ssh restart
fi
echo 'Info: 重新启动SSHd成功!'
fi

echo ' '
get_ip

# Use default SSH port 22. If you use another SSH port on your server
if [ -e "/etc/ssh/sshd_config" ]; then
	[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
	while :; do echo
    	read -p "请输入新的SSH端口（当前端口: $ssh_port): " SSH_PORT
    	[ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
    if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ]; then
    	break
    else
		echo 'Error: 输入错误！ 输入范围: 22,1025~65534'
    fi
  done

  if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ]; then
    sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
  elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
    sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
  fi

	if [ "${release}" = 'centos' ]; then
		service sshd restart
	else
		/etc/init.d/ssh restart
	fi
	echo 'Info: 重新启动SSHd成功!' && echo
#这里可以增加 防火墙 操作部分
	echo -e "Info: 是否关闭防火墙并禁止自启动?菜鸟建议关闭，老手请自行修改防火墙策略[Y/n]"
	read -p "(默认: y):" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ ${yn} == [Yy] ]]; then
		if [ "${release}" = "centos" ]; then
		chkconfig iptables off 2>/dev/null && service iptables stop 2>/dev/null
		systemctl disable firewalld 2>/dev/null && systemctl stop firewalld 2>/dev/null
		echo  "Info: ${release} 防火墙关闭并禁止自启动（老手自理）"
		else
		apt-get -y remove iptables  #卸载命令
		apt-get -y remove --auto-remove iptables   #删除依赖包
		apt-get -y purge iptables   #清除规则
		apt-get -y purge --auto-remove iptables  #清除配置文件等等
		#echo  "Info: ${release} 防火墙默认没安装，故此没有判断（老手自理）"
		systemctl stop firewalld
		systemctl disable firewalld
		fi
		if [ "${release}" = 'centos' ]; then
			service sshd restart
		else
			/etc/init.d/ssh restart
		fi
		echo 'Info: 重新启动SSHd成功!' && echo
	fi
fi

echo -e "Info: 是否[取消显示]每次登陆提示的历史IP(lastlogin)？[Y/n]"
read -p "(默认: y):" yn
[[ -z "${yn}" ]] && yn="y"
if [[ ${yn} == [Nn] ]]; then
	echo && echo "Info: 跳过本设置..." && echo
else
	if [ -z "`grep ^PrintLastLog /etc/ssh/sshd_config`" ]; then
	sed -i "s@^#PrintLastLog.*@&\nPrintLastLog no@" /etc/ssh/sshd_config
	else
	sed -i "s@^PrintLastLog.*@PrintLastLog no@" /etc/ssh/sshd_config
	fi
if [ "${release}" = 'centos' ]; then
	service sshd restart
else
	/etc/init.d/ssh restart
fi
	echo 'Info: 不显示每次登陆显示的IP 设置完毕!'
	echo 'Info: 此功能可能需要重启系统才能生效!'
fi


echo 'Info: -----------------------'
echo
echo -e "Info: 是否安装shell命令美化?[Y/n]"
read -p "(默认: y):" yn
[[ -z "${yn}" ]] && yn="y"
if [[ ${yn} == [Yy] ]]; then
	SHELL_ZZH=1
	if [ "${release}" = "centos" ]; then
		yum -y install wget git #zsh
	else
		apt-get update -y
		apt-get -y install wget curl git #zsh
	fi
fi


if [ ${SHELL_ZZH} -eq 1 ]; then
	#chsh -s /bin/zsh
	#echo "Info: 安装oh-my-zsh"
  	#sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	echo '' > /etc/motd
	wget -O /usr/bin/screenfetch-dev https://raw.githubusercontent.com/wxlost/shell/master/ca/include/screenfetch-dev
	chmod +x /usr/bin/screenfetch-dev
	wget -O /etc/profile.d/logo.sh https://raw.githubusercontent.com/wxlost/shell/master/ca/include/logo.sh
	clear
	#echo "Info: 安装oh-my-zsh完毕"
	echo "Info: 安装shell命令美化完毕,请重新连接ssh即可查看效果" && echo
# Custom profile
cat > /etc/profile.d/oneinstack.sh << EOF
HISTSIZE=10000
PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\\\$ "
HISTTIMEFORMAT="%F %T \$(whoami) "

alias l='ls -AFhlt'
alias lh='l | head'
alias vi=vim

GREP_OPTIONS="--color=auto"
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
EOF

fi

#以下为我个人用的自定义

echo "Info: Linux history 命令记录加执行时间戳以及记录到日志" && echo
[ -z "$(grep ^'PROMPT_COMMAND=' /etc/bashrc)" ] && cat >> /etc/bashrc << EOF
PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });logger "[euid=\$(whoami)]":\$(who am i):[\`pwd\`]"\$msg"; }'
EOF
echo "Info: 配置 limits.conf (65535)" && echo
# /etc/security/limits.conf
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF