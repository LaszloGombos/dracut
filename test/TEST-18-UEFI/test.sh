#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="UEFI boot"

ovfm_code() {
    for path in \
        "/usr/share/OVMF/OVMF_CODE.fd" \
        "/usr/share/edk2/x64/OVMF_CODE.fd" \
        "/usr/share/edk2-ovmf/OVMF_CODE.fd" \
        "/usr/share/qemu/ovmf-x86_64-4m-code.bin"; do
        [[ -s $path ]] && echo -n "$path" && return
    done
}

test_check() {
    [[ -n "$(ovfm_code)" ]]
}

KVERSION="${KVERSION-$(uname -r)}"

DRACUT_ARGS+=(--local --no-hostonly --no-early-microcode --nofscks --modules rootfs-block --modules test)
KERNEL_ARGS+=(panic=1 oops=panic "console=ttyS0,115200n81" "$DEBUGFAIL")

test_marker_reset() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
}

test_marker_check() {
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_run() {
    declare -a disk_args=()
    declare -i disk_index=1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/squashfs.img root

    test_marker_reset
    "$testdir"/run-qemu "${disk_args[@]}" -net none \
        -drive file=fat:rw:"$TESTDIR"/ESP,format=vvfat,label=EFI \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,file="$(ovfm_code)",readonly=on
    test_marker_check
}

test_setup() {
    # Create what will eventually be our root filesystem
    "$basedir"/dracut.sh --local --no-hostonly --no-early-microcode --nofscks \
        --tmpdir "$TESTDIR" --keep --modules "test-root" --include ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc
    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/squashfs.img -quiet -no-progress

    mkdir -p "$TESTDIR"/ESP/EFI/BOOT

    if [ -f "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" ]; then
        DRACUT_ARGS+=(--uefi-stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub)
    elif [ -f "/usr/lib/gummiboot/linuxx64.efi.stub" ]; then
        DRACUT_ARGS+=(--uefi-stub /usr/lib/gummiboot/linuxx64.efi.stub)
    fi

    "$basedir"/dracut.sh "${DRACUT_ARGS[@]}" \
        --kernel-cmdline "root=/dev/disk/by-id/ata-disk_root ${KERNEL_ARGS[*]}" \
        --uefi --drivers "sd_mod squashfs" \
        "$TESTDIR"/ESP/EFI/BOOT/BOOTX64.efi "$KVERSION" || return 1
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
