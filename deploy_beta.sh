#!/bin/bash

function checkOS() {
	# Check OS version
	if [[ -e /etc/debian_version ]]; then
		source /etc/os-release
		OS="${ID}" # debian or ubuntu
	elif [[ -e /etc/centos-release ]]; then
		OS=centos
	else
		echo "Looks like you aren't running this installer on a Debian, Ubuntu or CentOS Linux system"
		exit 1
	fi
}

function installSoftware() {
	# Install tools and module
	if [[ ${OS} == 'ubuntu' ]]; then
		apt-get update
                apt-get -y install strongswan xl2tpd net-tools
#                echo "ubuntu install..."
	elif [[ ${OS} == 'centos' ]]; then
                yum -y install epel-release
                yum --enablerepo=epel -y install strongswan xl2tpd net-tools
#                echo "centos install..."
	fi
}

function backUpAndSetup() { 
        mv /etc/ipsec.conf /etc/ipsec.conf.bak
        mv /etc/ipsec.secrets /etc/ipsec.secrets.bak
        mv /etc/xl2tpd/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf.bak
	
	cp ./config/ipsec.conf /etc/ipsec.conf
	cp ./config/ipsec.secrets /etc/ipsec.secrets
	cp ./config/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
        cp ./config/options.l2tpd.client /etc/ppp/options.l2tpd.client
}

checkOS
installSoftware
backUpAndSetup

