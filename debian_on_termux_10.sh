#!/data/data/com.termux/files/usr/bin/sh

# oldstable, stable, testing, unstable
BRANCH=stable
# base(258M), minbase(217M), buildd, fakechroot
VAR=minbase
# list_close_debian_mirrors.sh
REPO=http://ftp.debian.org/debian/

set -e
trap '[ $? -eq 0 ] && exit 0 || (echo; echo "termux-info:"; termux-info)' EXIT

if [ ! -d ~/debian-$BRANCH ] ; then
        ARCH=$(uname -m)
        case $ARCH in
                aarch64) ARCH=arm64 ;;
                x86_64) ARCH=amd64 ;;
                i686) ARCH=i386 ;;
                armv7l) ARCH=armhf ;;
                armv8l) apt-get -qq install getconf; if [ $(getconf LONG_BIT) -eq 64 ]; then ARCH=arm64; else ARCH=armhf; fi ;;
                *) echo "Unsupported architecture $ARCH"; exit ;;
        esac
        apt-get -qq update
        apt-get -qq dist-upgrade
        pkg i debootstrap tsu wget
        debootstrap \
                --variant=$VAR \
                --exclude=systemd \
                --arch=$ARCH \
                $BRANCH \
                ~/debian-$BRANCH \
                $REPO
fi
unset LD_PRELOAD

# The path of Ubuntu rootfs
ROOTFS=~/debian-$BRANCH

#sudo mount -o remount,dev,suid /data

sudo mount --bind /dev $ROOTFS/dev
sudo mount --bind /sys $ROOTFS/sys
sudo mount --bind /proc $ROOTFS/proc
sudo mount -t devpts devpts $ROOTFS/dev/pts

# /dev/shm for Electron apps
#sudo mount -t tmpfs -o size=256M tmpfs $ROOTFS/dev/shm

# chroot (for networking link rootfs dir to `$PREFIX/var/lib/proot-distro/installed-rootfs/debian` proot & login: `proot-distro login debian` on Android 11+)
sudo chroot $ROOTFS /bin/su - root

sleep 2

#sudo umount $ROOTFS/dev/shm
sudo umount -lf $ROOTFS/dev/pts
sudo umount -lf $ROOTFS/dev
sudo umount -lf $ROOTFS/proc
sudo umount -lf $ROOTFS/sys
