export KERNEL='6.3.7'

cd /tmp/linux-$KERNEL

cat > x86_64.miniconf << EOF
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_BLK_DEV=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_RD_GZIP=y
CONFIG_TMPFS=y
CONFIG_COMPAT_32BIT_TIME=y
CONFIG_RTC_CLASS=y

# x86 specific
CONFIG_64BIT=y

CONFIG_DEVTMPFS=y

# EFI
CONFIG_EFI_HANDOVER_PROTOCOL=y
CONFIG_EFI_STUB=y
CONFIG_EFI=y
CONFIG_ACPI=y

# ahci, libahci, libata
# ahci depends on libahci and libata
CONFIG_SATA_AHCI=y
CONFIG_PCI=y
CONFIG_ATA=y

# sd_mod SCSI disk support
CONFIG_BLK_DEV_SD=y

# squashfs
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_ZLIB=y
CONFIG_MISC_FILESYSTEMS=y

# 8250 (optional but need dracut testcase change) serial console
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_SERIAL_8250=y
EOF

make ARCH=x86 KCONFIG_ALLCONFIG=x86_64.miniconf allnoconfig
cat .config
make -j$(nproc) bzImage
rm -rf /boot/* /lib/modules/*
make install
cd / && rm -rf /tmp/linux-$KERNEL
mkdir -p /lib/modules/$KERNEL
