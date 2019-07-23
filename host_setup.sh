#!/bin/bash
#
# This script presumes the interface eth0 is connected to the internal network for PXE boot
#

# Install packages
yum -y install vim dhcp tftp xinetd tftp-server syslinux syslinux-tftpboot httpd dnsmasq git

# Configure network
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
TYPE=Ethernet
DEFROUTE=no
BOOTPROTO=static
IPADDR=10.10.0.1
NETMASK=255.255.0.0
NETWORK=10.10.0.0
ZONE=trusted
PEERDNS=no
EOF

ifup eth0

# Configure httpd
mkdir -p /var/www/netboot
cat << EOF > /etc/httpd/conf.d/netboot.conf
<Directory /var/www/netboot/>
    Options Indexes MultiViews FollowSymlinks
    AllowOverride None
    Require all granted
    Order Allow,Deny
    Allow from all
</Directory>
Alias /netboot /var/www/netboot/
EOF
systemctl start httpd
systemctl enable httpd

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
    APPEND initrd=boot/initrd-diskless-example root=live:http:http://10.10.0.1/netboot/diskless-example.img rw selinux=0 console=tty0 console=ttyS0,115200n8

LABEL local
    MENU LABEL (local)
    MENU DEFAULT
    LOCALBOOT 0
EOF

systemctl enable xinetd
systemctl restart xinetd

# Download scripts
git clone https://github.com/openflighthpc/flight-images /root/flight-images


