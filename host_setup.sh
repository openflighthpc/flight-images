#!/bin/bash
#
# This script presumes the interface eth0 is connected to the internal network for PXE boot
#

INTERFACE=${INTERFACE:-eth0}
IP=${IP:-10.10.0.1}
NETMASK=${NETMASK:-255.255.0.0}
NETWORK=${NETWORK:-10.10.0.0}

DHCPRANGE=${DHCPRANGE:-10.10.200.10 10.10.200.200}

EXTERNALINTERFACE=${EXTERNALINTERFACE:-eth1}

IMAGEBASE=${IMAGEBASE:-/export/images}
EXPORT=${EXPORT:-/images}

# Install packages
yum -y install vim dhcp tftp xinetd tftp-server syslinux syslinux-tftpboot httpd dnsmasq git qemu-img squashfs-tools nfs-utils

# Configure network
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
DEVICE=eth0
ONBOOT=yes
TYPE=Ethernet
DEFROUTE=no
BOOTPROTO=static
IPADDR=$IP
NETMASK=$NETMASK
NETWORK=$NETWORK
ZONE=trusted
PEERDNS=no
EOF

systemctl restart network

# DHCP
cat << EOF > /etc/dhcp/dhcpd.conf
omapi-port 7911;

default-lease-time 43200;
max-lease-time 86400;
ddns-update-style none;
option domain-name-servers $IP;

allow booting;
allow bootp;

option fqdn.no-client-update    on;  # set the "O" and "S" flag bits
option fqdn.rcode2            255;
option pxegrub code 150 = text ;

option space PXE;
option PXE.mtftp-ip    code 1 = ip-address;
option PXE.mtftp-cport code 2 = unsigned integer 16;
option PXE.mtftp-sport code 3 = unsigned integer 16;
option PXE.mtftp-tmout code 4 = unsigned integer 8;
option PXE.mtftp-delay code 5 = unsigned integer 8;
option arch code 93 = unsigned integer 16; # RFC4578

# PXE Handoff.
next-server $IP;
filename "pxelinux.0";

log-facility local7;

subnet $NETWORK netmask $NETMASK {
  pool
  {
    range $DHCPRANGE;
  }
  option routers $IP;
}
EOF

systemctl start dhcp

# Configure httpd
mkdir -p $IMAGEBASE
cat << EOF > /etc/httpd/conf.d/images.conf
<Directory $IMAGEBASE/>
    Options Indexes MultiViews FollowSymlinks
    AllowOverride None
    Require all granted
    Order Allow,Deny
    Allow from all
</Directory>
Alias $EXPORT $IMAGEBASE/
EOF
systemctl start httpd
systemctl enable httpd

# NFS setup
echo "$IMAGEBASE  *(rw,no_root_squash)" > /etc/exports
systemctl start nfs
systemctl enable nfs
exportfs -va

# Configure TFTP
sed -ie "s/^.*disable.*$/\    disable = no/g" /etc/xinetd.d/tftp

mkdir -p /var/lib/tftpboot/{boot,pxelinux.cfg}

cat << EOF > /var/lib/tftpboot/pxelinux.cfg/default
DEFAULT menu
PROMPT 0
MENU TITLE PXE Menu
TIMEOUT 100
TOTALTIMEOUT 1000
ONTIMEOUT diskless-example

LABEL diskless-example
    MENU LABEL diskless-example
    KERNEL boot/kernel-diskless-example
    APPEND initrd=boot/initrd-diskless-example root=live:http:http://$IP$EXPORT/diskless-example.img rw selinux=0 console=tty0 console=ttyS0,115200n8

LABEL local
    MENU LABEL (local)
    MENU DEFAULT
    LOCALBOOT 0
EOF

systemctl enable xinetd
systemctl restart xinetd

# DNS & IP Forwarding
systemctl start dnsmasq
systemctl enable dnsmasq

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --set-target=ACCEPT --zone internal --permanent
firewall-cmd --zone internal --add-interface $INTERFACE --permanent

firewall-cmd --new-zone external --permanent
firewall-cmd --zone external --add-interface $EXTERNALINTERFACE --permanent

firewall-cmd --reload

# Download scripts
git clone https://github.com/openflighthpc/flight-images /root/flight-images

# Write config file
cat << EOF > /root/flight-images/config.sh
INTERFACE="$INTERFACE"
IP="$IP"
NETMASK="$NETMASK"
NETWORK="$NETWORK"
DHCPRANGE="$DHCPRANGE"
EXTERNALINTERFACE="$EXTERNALINTERFACE"
IMAGEBASE="$IMAGEBASE"
EXPORT="$EXPORT"
EOF

