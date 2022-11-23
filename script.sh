#!/bin/bash

echo '
# The loopback network interface
auto lo
iface lo inet loopback

# The WAN network interface
auto ens4
iface ens4 inet static
	address 192.168.122.100
	netmask 255.255.255.0
	gateway 192.168.122.1

# The LAN network interface
auto ens5
iface ens5 inet static
	address 192.168.0.1
	netmask 255.255.255.0

' > /etc/network/interfaces

echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

sudo apt update
sudo apt install -y nftables
sudo systemctl enable nftables
sudo systemctl start nftables

mkdir -p /etc/nat/
touch /etc/nat/nat_ruleset.nft

echo '#!/usr/sbin/nft -f

flush ruleset
add table nat
add chain nat prerouting { type nat hook prerouting priority -100 ; }
add chain nat postrouting { type nat hook postrouting priority 100 ; }
add rule nat postrouting oifname "ens4" masquerade
add rule nat postrouting oifname "ens4" snat to 192.168.122.100
add rule nat prerouting iifname ens4 dnat to 192.168.0.0/24
' > /etc/nat/nat_ruleset.nft

touch /etc/rc.local

echo '#!/bin/bash

nft -f /etc/nat/nat_ruleset.nft
' > /etc/rc.local
