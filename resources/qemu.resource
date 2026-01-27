*** Comments ***
# these are mostly cosmetic
# robocop: off=DOC01,LEN03,LEN08,NAME02,NAME18

# FIXME: I have no idea what it wants...
# https://forum.robotframework.org/t/depr05-set-suite-variable-used-instead-of-var-is-a-fool/9428/4
# robocop: off=DEPR05,VAR06,VAR07


*** Settings ***
Documentation       This resource provides access to QEMU specific Keywords.

Library             OperatingSystem
Library             Process


*** Keywords ***
Run "${image}" with "${memory}" MB memory "${cpus}" cpus and "${serial_port_path}" serial port
    Set Test Variable    ${memory}    ${memory}
    Set Test Variable    ${cpus}    ${cpus}
    Set Test Variable    ${serial_port_path}    ${serial_port_path}
    Set Test Variable    ${image}    ${image}
    ${random} =    Evaluate    random.randint(0,sys.maxsize)    modules=random, sys
    ${result} =    Run Buffered Process    cp ${image} /tmp/resin${random}.img    shell=yes
    Process ${result}
    Set Test Variable    ${image_copy}    /tmp/resin${random}.img

    # detect image architecture by checking for ARM64 EFI bootloader
    ${result} =    Run Buffered Process    strings ${image} | grep -Eo "BOOTAA64"    shell=yes
    Run Keyword And Return If    ${result.rc} == 0    Run aarch64 image

    # firmware is 'dos' (legacy x86 DTs) or 'gpt' (generic-amd64 DT)
    ${result} =    Run Buffered Process
    ...    fdisk -l "${image}" | sed -nE 's/^Disklabel type: (\\w+)$/\\1/p'
    ...    shell=yes
    Process ${result}
    Set Test Variable    ${firmware}    ${result.stdout}

    # https://www.qemu.org/docs/master/system/qemu-manpage.html
    # .. depending on the target architecture: kvm, xen, hvf, nvmm, whpx (default: tcg)
    ${result} =    Run Buffered Process    test -r /dev/kvm && test -w /dev/kvm    shell=yes
    Run Keyword And Return If    ${result.rc} == 0    Run "${firmware}" image with "kvm" acceleration
    Run Keyword And Return If    ${result.rc} != 0    Run "${firmware}" image with "tcg" acceleration

Run aarch64 image
    # https://www.qemu.org/docs/master/system/qemu-manpage.html
    # .. depending on the target architecture: kvm, xen, hvf, nvmm, whpx (default: tcg)
    ${result} =    Run Buffered Process    test -r /dev/kvm && test -w /dev/kvm    shell=yes
    Run Keyword And Return If    ${result.rc} == 0    Run "aarch64" image with "kvm" acceleration
    Run Keyword And Return If    ${result.rc} != 0    Run "aarch64" image with "tcg" acceleration

Run "gpt" image with "${acceleration}" acceleration
    # qemu-system-x86_64 defunct process without shell
    ${handle} =    Start Process
    ...    qemu-system-x86_64 -device ahci,id\=ahci -drive file\=${image_copy},media\=disk,cache\=none,format\=raw,if\=none,id\=disk -device ide-hd,drive\=disk,bus\=ahci.0 -device virtio-net-pci,netdev\=n1 -netdev \"user,id\=n1,dns\=127.0.0.1,guestfwd\=tcp:10.0.2.100:80-cmd:netcat haproxy 80,guestfwd\=tcp:10.0.2.100:443-cmd:netcat haproxy 443\" -m ${memory} -nographic -machine type\=q35 -accel ${acceleration} -smp ${cpus} -chardev socket,id\=serial0,path\=${serial_port_path},server\=on,wait\=off -serial chardev:serial0 -bios /usr/share/ovmf/OVMF.fd -nodefaults
    ...    shell=yes
    RETURN    ${handle}

Run "dos" image with "${acceleration}" acceleration
    # qemu-system-x86_64 defunct process without shell
    ${handle} =    Start Process
    ...    qemu-system-x86_64 -device ahci,id\=ahci -drive file\=${image_copy},media\=disk,cache\=none,format\=raw,if\=none,id\=disk -device ide-hd,drive\=disk,bus\=ahci.0 -device virtio-net-pci,netdev\=n1 -netdev \"user,id\=n1,dns\=127.0.0.1,guestfwd\=tcp:10.0.2.100:80-cmd:netcat haproxy 80,guestfwd\=tcp:10.0.2.100:443-cmd:netcat haproxy 443\" -m ${memory} -nographic -machine type\=pc -accel ${acceleration} -smp ${cpus} -chardev socket,id\=serial0,path\=${serial_port_path},server\=on,wait\=off -serial chardev:serial0
    ...    shell=yes
    RETURN    ${handle}

Run "aarch64" image with "${acceleration}" acceleration
    # qemu-system-aarch64 defunct process without shell
    # Resize image to 4G otherwise the data partition isn't big enough for user apps
    ${result} =    Run Buffered Process    qemu-img resize ${image_copy} 4G    shell=yes
    Process ${result}
    ${handle} =    Start Process
    ...    qemu-system-aarch64 -drive file\=${image_copy},media\=disk,cache\=none,format\=raw -device virtio-net-device,netdev\=n1 -netdev \"user,id\=n1,dns\=127.0.0.1,guestfwd\=tcp:10.0.2.100:80-cmd:netcat haproxy 80,guestfwd\=tcp:10.0.2.100:443-cmd:netcat haproxy 443\" -m ${memory} -nographic -machine type\=virt -accel ${acceleration} -smp ${cpus} -chardev socket,id\=serial0,path\=${serial_port_path},server\=on,wait\=off -serial chardev:serial0 -cpu cortex-a72 -bios /usr/share/AAVMF/AAVMF_CODE.fd -nodefaults
    ...    shell=yes
    RETURN    ${handle}
