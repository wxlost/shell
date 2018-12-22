# server
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
cd /root && wget -O 55R.sh https://raw.githubusercontent.com/wxlost/shell/master/server/55R.sh && chmod +x 55R.sh && bash 55R.sh 参数
```


##### 2. 在 wget 时去掉 --no-check-certificate 参数
##### 3. 如果遇到 "wget ... not trusted ..." 这种报错，不要使用 no-check-certificate 这个参数，这是治标不治本的方法，还后患无穷。正确的解决方法是：
`apt-get install -y ca-certificates` 或 `yum install -y ca-certificates`