#!/bin/bash

mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

service strongswan restart
service xl2tpd restart

sleep 0.5
ipsec up myvpn

sleep 1.5
echo "c myvpn" > /var/run/xl2tpd/l2tp-control

sleep 5
echo "Configuring IP routing talbe..."

# 添加本地IP 和 本地网关IP
route add 0.0.0.0 gw 0.0.0.0

# 添加vpn服务器IP 和 本地网关IP
route add 0.0.0.0 gw 0.0.0.0

#route del -net 0.0.0.0 netmask 255.255.255.255 dev eth0

route add default dev ppp0

#ifmetric ppp0 120
