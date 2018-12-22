# ca
## 本人自用 和 常用脚本临时测试


### 2.秘钥登陆
#### 需要网站支持-公钥保存为文本，然后上传到你的网站。

##### 比如上传后访问链接为 https://myhome.com/tools/wtf.pub 那么 你的参数就是 https://myhome.com/tools/wtf.pub
### 请注意！！区分http和https
##### 参数2 固定为 -P 效果是关闭密码登陆增加安全性
```
cd /root && wget -O ca.sh https://raw.githubusercontent.com/wxlost/shell/master/ca/ca.sh && chmod +x ca.sh && bash ca.sh https://myhome.com/tools/wtf.pub
```

### 原始脚本-参数2 固定为 -P 效果是关闭密码登陆增加安全性
```
cd /root && wget -O ca.sh https://raw.githubusercontent.com/wxlost/shell/master/ca/ca.sh && chmod +x ca.sh && bash ca.sh 参数1 -p
```



#内置的美化脚本
## 安装完成预览
![](https://s1.ax1x.com/2018/02/03/9Z7FaT.png)

## oh-my-zsh主题查看
## 注意!主题仅限MAC才有效果,故此未实装,有需要的自己去安装oh-my-zsh脚本
https://github.com/robbyrussell/oh-my-zsh/wiki/Themes