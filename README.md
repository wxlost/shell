# shell
## 本人自用 和 常用脚本临时测试


### 1.后端-安装到 /home 。大约需要2G硬盘空间
##### 需要网站支持-将脚本下载到本地，修改内容后上传到你的网站(publi目录下)。
```
wget -O `pwd`/options.conf https://raw.githubusercontent.com/wxlost/shell/master/server/options.conf
```
##### 比如上传后访问链接为 https://myhome.com/options.conf 那么 你的参数就是 myhome.com
```
cd /root && wget -O 55R.sh https://raw.githubusercontent.com/wxlost/shell/master/server/55R.sh && chmod +x 55R.sh && bash 55R.sh myhome.com
```
##### 初次使用需要用上面的下载，后续执行本脚本
```
bash 55R.sh myhome.com
```

### 原始脚本
```
NAME="55R" && cd /root && wget -O $NAME.sh https://raw.githubusercontent.com/wxlost/shell/master/server/$NAME.sh && chmod +x $NAME.sh && bash $NAME.sh 参数
```




# 2.秘钥登陆
#### 需要网站支持-公钥保存为文本，然后上传到你的网站。

##### 比如上传后访问链接为 https://myhome.com/tools/wtf.pub 那么 你的参数就是 https://myhome.com/tools/wtf.pub
#### 请注意！！区分http和https
##### 参数2 固定为 -P 效果是关闭密码登陆增加安全性
```
cd /root && wget -O ca.sh https://raw.githubusercontent.com/wxlost/shell/master/ca/ca.sh && chmod +x ca.sh && bash ca.sh https://myhome.com/tools/wtf.pub
```

### 原始脚本-参数2 固定为 -P 效果是关闭密码登陆增加安全性
```
cd /root && wget -O ca.sh https://raw.githubusercontent.com/wxlost/shell/master/ca/ca.sh && chmod +x ca.sh && bash ca.sh 参数1 -p
```


#内置的美化脚本
#### 安装完成预览
![](https://s1.ax1x.com/2018/02/03/9Z7FaT.png)

#### oh-my-zsh主题查看
#### 注意!主题仅限MAC才有效果,故此未实装,有需要的自己去安装oh-my-zsh脚本
https://github.com/robbyrussell/oh-my-zsh/wiki/Themes




# 3.伪装
```
NAME="caddy_install" && wget -O $NAME.sh https://raw.githubusercontent.com/wxlost/shell/master/caddy/$NAME.sh && chmod +x $NAME.sh && bash $NAME.sh install http.filemanager
```
```
NAME="caddy_onepvp" && wget -O $NAME.sh https://raw.githubusercontent.com/wxlost/shell/master/caddy/$NAME.sh && chmod +x $NAME.sh && bash $NAME.sh install http.filemanager
```