# ipsec_vpn_client
The script of client deploy based on https://github.com/hwdsl2/setup-ipsec-vpn

# L2TP+IPsec 客户端配置



# VPN方案 - L2TP+IPsec

参考ipsec项目启动ipsec客户端，以尝试连接到ipsec服务器

> [https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#%E4%BD%BF%E7%94%A8%E5%91%BD%E4%BB%A4%E8%A1%8C%E9%85%8D%E7%BD%AE-linux-vpn-%E5%AE%A2%E6%88%B7%E7%AB%AF](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#使用命令行配置-linux-vpn-客户端)



## 配置 /etc/ipsec.conf

将`right`参数替换为服务器公网IP地址

```
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
  # strictcrlpolicy=yes
  # uniqueids = no

# Add connections here.

# Sample VPN connections

conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=1
  keyexchange=ikev1
  authby=secret
  ike=aes128-sha1-modp2048!
  esp=aes128-sha1-modp2048!

conn myvpn
  keyexchange=ikev1
  left=%defaultroute
  auto=add
  authby=secret
  type=transport
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=x.x.x.x
#  right=$VPN_SERVER_IP
```



### 配置 ipsec.secrets

/etc/ipsec.secrets

```
: PSK "xxxxxxx"
```



## 配置 /etc/xl2tpd/xl2tpd.conf

将`lns`替换为服务器公网IP地址

```
[lac myvpn]
lns = x.x.x.x
;lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
```



## 配置 /etc/ppp/options.l2tpd.client

将`user`和`password`替换为用户名和密码，`user`默认值为`vpnuser`。

```
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name root
remotename myvpn
user "xxxx"
password "xxxxx"
debug
```





## 快速调试脚本

**start.sh**

```
#!/bin/bash
  
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

service strongswan restart
service xl2tpd restart

sleep 0.5
ipsec up myvpn

sleep 1.5
echo "c myvpn" > /var/run/xl2tpd/l2tp-control
```



**stop.sh**

```
#!/bin/bash
echo "d myvpn" > /var/run/xl2tpd/l2tp-control
ipsec down myvpn
```









**l2tp已经建立，但是ppp0连接未启动**

使用`pppstats`命令查看ppp连接状态

解决办法：

1. 排查相关配置文件中关于环境变量的引用是否成功，如果不成功，可以选择在配置文件中写死。也即不在配置文件中使用环境变量，例如`${VPN_SERVER_IP}`这样的变量
2. 检查`/etc/ppp/option.l2tpd.client`文件中，关于客户端的用户名和账号是否正确。

搭建过程中，通过解决上述两点问题后，成功使用

`echo "c myvpn" > /var/run/xl2tpd/l2tp-control`

命令拨通了ppp连接，`ifconfig`可看到`ppp0`连接。

注意，此时客户端的本机出口IP并未改变，仍然是原有IP，需要继续按照文档配置网关路由。



问题的排查均可使用`journalctl -xef`来试试观察日志。



**将数据路由到ppp0接口时，远程ssh会断掉**

问题现象：

执行了`route add default dev ppp0`命令后，ssh掉线，只能通过vnc访问主机。

问题原因：

执行上述命令后，vnc登陆后查看路由表如下：

```
route -n
(现场丢失)

```

可以看到第一条路由将dest为任意地址的包都路由到了ppp0接口，所以其中也包括ssh的包，导致ssh掉线。

解决办法：

> https://netbeez.net/blog/linux-set-route-priorities/

调整路由规则的Metric值，使dest为客户端主机公网IP的包，优先通过eth0来路由。达到这个效果，只需要保证ppp0接口的metric值小于eth0的即可。

使用工具`ifmetric`来配置，需要先安装。可使用命令`apt-cache show 命令`来查询命令对应的包名。

安装成功后，具体配置操作如下：

```
# ifmetric ppp0 120
```











## 
