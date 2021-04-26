#!/bin/bash

mac="12:00:02:e2:be:ce"
gateway="172.16.128.1"
dlower="172.16.128.2"
dupper="172.16.128.2"

pid=$(pgrep dnsmasq)

if [ -n $pid ]
then
	kill $pid > /dev/null 2>&1
fi	

wlp=$(find /sys/class/net -name "w*" | cut -d '/' -f5)
echo $wlp
iptables -t nat -A POSTROUTING -o $wlp -j MASQUERADE
sysctl net.ipv4.ip_forward=1 > /dev/null 2>&1
iptables -P FORWARD ACCEPT
iptables -F FORWARD

iw dev $wlp interface add ap0 type __ap > /dev/null 2>&1
ip addr flush ap0
ip addr add $gateway/24 dev ap0 > /dev/null 2>&1

ip link set ap0 down
ip link set ap0 addr $mac
ip link set ap0 up
cat > /etc/dnsmasq.conf << EOF
interface=ap0
dhcp-range=$dlower,$dupper,2m
EOF

dnsmasq

cat > /etc/hostapd.conf << EOF
interface=ap0
driver=nl80211
ssid=testnet
channel=1
hw_mode=g
EOF

hostapd /etc/hostapd.conf
