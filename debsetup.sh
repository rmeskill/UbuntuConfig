#!/bin/bash

if [[ "$USER" != 'root' ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

if [[ -e /etc/debian_version ]]; then
	OS=debian
	RCLOCAL='/etc/rc.local'
else
	echo "Looks like you aren't running this installer on a Debian or Ubuntu system"
	exit
fi

# Try to get our IP from the system and fallback to the Internet.
# I do this to make the script compatible with NATed servers (lowendspirit.com)
# and to avoid getting an IPv6.
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
		IP=$(wget -qO- ipv4.icanhazip.com)
fi

echo "This server's public IP is: $IP"
echo " "

read -p "What is this server's FQDN: " FQDN
read -p "What is this server's physical location (City, State/Country): " Location
read -p "What is the SNMP RO Community string: " SNMP
read -p "What is the IP address of your SNMP monitoring server: " SNMP_IP

apt-get update
apt-get upgrade -y 
apt-get install snmpd ufw locate -y

ufw allow ssh/tcp
ufw allow proto udp from $SNMP_IP to any port 161
ufw enable

mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.bak
touch /etc/snmp/snmpd.conf
echo "rocommunity $SNMP" >> /etc/snmp/snmpd.conf
echo "syslocation $Location" >> /etc/snmp/snmpd.conf

updatedb
