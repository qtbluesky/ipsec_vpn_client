#!/bin/bash
echo "d myvpn" > /var/run/xl2tpd/l2tp-control
ipsec down myvpn

