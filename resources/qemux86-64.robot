*** Settings ***
Documentation    This resource provides access to qemux86_64 specific Keywords.
Library   Process
Library   OperatingSystem

*** Variables ***

*** Keywords ***
Run ${image} with ${memory} MB memory and ${cpus} cpus
    ${handle} =  Start Process    qemu-system-x86_64 -drive file\=${image},media\=disk,cache\=none,format\=raw -net nic,model\=virtio -net user -m ${memory} -nographic -machine type\=pc,accel\=kvm -smp ${cpus}    shell=yes
    Return From Keyword    ${handle}
