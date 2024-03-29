#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/config.sh

IMAGENAME=$1
IMAGE=${IMAGEBASE}/${IMAGENAME}

READONLYROOT=1
CUSTOMSCRIPT=0

if [ -z "${IMAGENAME}" ]; then
  echo "Provide an image name" >&2
  exit 1
elif [ -e ${IMAGE} ]; then 
  echo "Image exists" >&2
  exit 1
fi

read -p "Root password for image: " PASSWORD
while [[ -z "$PASSWORD" ]] ; do
    echo "ERROR: Answer cannot be blank"
    read -p "Root password for image: " PASSWORD
done

mkdir -p $IMAGE

#INSTALL A ROOT
#yum groups -c /export/service/image/cluster.repo -y install "Compute Node" "Core" --releasever=7 --installroot=$IMAGE
yum groups -y install "Compute Node" "Core" --releasever=7 --installroot=$IMAGE
#yum -c /export/service/image/cluster.repo -y install vim emacs xauth xhost xdpyinfo xterm xclock tigervnc-server ntpdate vconfig bridge-utils patch tcl-devel gettext wget dracut-network nfs-utils --installroot=$IMAGE
yum -y install vim emacs xauth xhost xdpyinfo xterm xclock tigervnc-server ntpdate vconfig bridge-utils patch tcl-devel gettext wget dracut-network nfs-utils --installroot=$IMAGE
cat << EOF > $IMAGE/etc/fstab
tmpfs   /dev/shm    tmpfs   defaults   0 0
sysfs   /sys        sysfs   defaults   0 0
proc    /proc       proc    defaults   0 0
EOF

#PREP IMAGE
sed -e 's/^SELINUX=.*$/SELINUX=disabled/g' -i $IMAGE/etc/sysconfig/selinux
cp -v $DIR/rwtab $IMAGE/etc/rwtab
#rm -rf /etc/rwtab.d/*

if [ ${READONLYROOT} -eq 1 ]; then
  sed -e 's/^TEMPORARY_STATE=.*$/TEMPORARY_STATE=yes/g' -i $IMAGE/etc/sysconfig/readonly-root
  sed -e 's/^READONLY=.*$/READONLY=yes/g' -i $IMAGE/etc/sysconfig/readonly-root
fi

#locale and security
ln -snf /usr/share/zoneinfo/Europe/London $IMAGE/etc/localtime
echo 'ZONE="Europe/London"' > $IMAGE/etc/sysconfig/clock
chroot $IMAGE usermod --password "$(openssl passwd -1 $PASSWORD)" root

#prep chroot
mount -o bind /proc $IMAGE/proc
mount -o bind /sys  $IMAGE/sys
mount -o bind /run  $IMAGE/run
mount -o bind /dev  $IMAGE/dev

KERNEL=`chroot $IMAGE rpm -q kernel | tail -n 1 | sed -e 's/^kernel-//g'`

# Use dracut to do networking
chroot $IMAGE systemctl enable NetworkManager
chroot $IMAGE systemctl disable network
chroot $IMAGE systemctl disable kdump

chroot $IMAGE dracut -N -a livenet -a dmsquash-live -a nfs -a biosdevname -f -v /boot/initrd.$IMAGENAME $KERNEL

# Example check for adding external configuration scripts to image
if [ ${CUSTOMSCRIPT} -eq 1 ]; then
  mkdir -p $IMAGE/var/lib/mycustomscript/bin/
  cp -v $DIR/mycustomscript.sh $IMAGE/var/lib/mycustomscript/bin/setup.sh
  chroot $IMAGE bash /var/lib/mycustomscript/bin/setup.sh
fi

# Tidy it up
chroot $IMAGE cp -v /boot/vmlinuz-$KERNEL /boot/kernel.$IMAGENAME
chroot $IMAGE yum clean all
umount -f $IMAGE/proc $IMAGE/sys $IMAGE/run $IMAGE/dev

sleep 5

chmod 644 $IMAGE/boot/initrd.$IMAGENAME
chmod 644 $IMAGE/boot/kernel.$IMAGENAME

# Put kernel and initrd in place
cp $IMAGE/boot/{initrd,kernel}.$IMAGENAME /var/lib/tftpboot/boot/

echo "Image done."
echo "-----------"
echo "Kernel: $IMAGE/boot/kernel.$IMAGENAME"
echo "InitRD: $IMAGE/boot/initrd.$IMAGENAME"
echo
echo "For NFS root, something like..."
echo "LABEL $IMAGENAME"
echo "     MENU LABEL $IMAGENAME"
echo "     KERNEL boot/kernel.$IMAGENAME"
echo "     APPEND initrd=boot/initrd.$IMAGENAME root=nfs:$IP:$EXPORT/$IMAGENAME rw selinux=0 console=tty0 console=ttyS0,115200n8"
echo


