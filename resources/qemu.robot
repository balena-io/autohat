*** Settings ***
Documentation    This resource provides access to QEMU specific Keywords.
Library   Process
Library   OperatingSystem

*** Variables ***

*** Keywords ***
Run "${image}" with "${memory}" MB memory "${cpus}" cpus and "${serial_port_path}" serial port
    Set Test Variable    ${memory}    ${memory}
    Set Test Variable    ${cpus}    ${cpus}
    Set Test Variable    ${serial_port_path}    ${serial_port_path}
    Set Test Variable    ${image}    ${image}
    ${random} =  Evaluate    random.randint(0,sys.maxsize)    modules=random, sys
    ${result} =  Run Buffered Process    cp ${image} /tmp/resin${random}.img    shell=yes
    Process ${result}
    Set Test Variable    ${image_copy}    /tmp/resin${random}.img
    ${result} =  Run Buffered Process    egrep -c '(vmx|svm)' /proc/cpuinfo    shell=yes
    Run Keyword And Return If    '${result.stdout}' == '0'    Run image with KVM disabled
    Run Keyword And Return If    '${result.stdout}' != '0'    Run image with KVM enabled

Run image with KVM enabled
    ${handle} =  Start Process    qemu-system-x86_64 -device ahci,id\=ahci -drive file\=${image_copy},media\=disk,cache\=none,format\=raw,if\=none,id\=disk -device ide-hd,drive\=disk,bus\=ahci.0 -net nic,model\=virtio -net user -m ${memory} -nographic -machine type\=pc,accel\=kvm -smp ${cpus} -chardev socket,id\=serial0,path\=${serial_port_path},server,nowait -serial chardev:serial0    shell=yes
    Return From Keyword    ${handle}

Run image with KVM disabled
    ${handle} =  Start Process    qemu-system-x86_64 -device ahci,id\=ahci -drive file\=${image_copy},media\=disk,cache\=none,format\=raw,if\=none,id\=disk -device ide-hd,drive\=disk,bus\=ahci.0 -net nic,model\=virtio -net user -m ${memory} -nographic -machine type\=pc -smp ${cpus} -chardev socket,id\=serial0,path\=${serial_port_path},server,nowait -serial chardev:serial0    shell=yes
    Return From Keyword    ${handle}
