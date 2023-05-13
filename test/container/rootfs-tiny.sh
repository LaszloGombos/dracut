#!/bin/sh

apk update && apk upgrade

apk add make kmod-dev musl-fts-dev g++ # build dracut
apk add bash cpio coreutils gawk grep binutils gzip # run dracut on host
apk add ovmf gummiboot qemu-system-x86_64 squashfs-tools # run the test

# custom busybox
apk add linux-headers bzip2 findutils make g++
cd /
mkdir /usr/bin
wget --quiet https://busybox.net/downloads/busybox-1.36.1.tar.bz2
bzip2 -d busybox-*.tar.bz2 && tar -xf busybox-*.tar && cd busybox-*
# TODO "make allnoconfig" to disable everything first like we do with the kernel
cp "$REPO/test/container/busyboxconfig" .config
make oldconfig
diff "$REPO/test/container/busyboxconfig" .config
LDFLAGS="--static" make
strip ./busybox
mv ./busybox /usr/bin/busybox
cd /
rm -rf busybox*
cd /bin && rm -rf sh && ln -sf /usr/bin/busybox sh && rm -rf /bin/busybox
find -L /bin /sbin /usr/bin /usr/sbin -type l -delete
/usr/bin/busybox --install -s
cp /usr/bin/busybox /bin/busybox
apk del linux-headers bzip2

# remove subset of coreutils
rm -rf /bin/df
rm -rf /usr/bin/du
rm -rf /usr/bin/less

touch /sbin/udevd /bin/udevadm
chmod +x /sbin/udevd /bin/udevadm
