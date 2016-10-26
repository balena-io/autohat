*** Settings ***
Documentation    This resource provides access to host OS.
Library   Process
Library   OperatingSystem
Library   String
Library   Collections

*** Variables ***

*** Keywords ***
Set up loop device for "${path_to_image}"
    ${result} =  Run Process    losetup -f -P ${path_to_image}    shell=yes
    Process ${result}
    ${result_loop} =  Run Process    lsblk | grep 7: | tail -1 | awk -F: '{ print $2 }' | cut -d ' ' -f 1    shell=yes
    Process ${result_loop}
    Should Not Be Empty     ${result_loop.stdout}   msg="Couldn't find the loop device"
    [Return]    ${result_loop.stdout}

Mount "${path}" on "${mount_destination}"
    ${result} =  Run Process    mount ${path} ${mount_destination}      shell=yes
    Process ${result}

Check host OS fingerprint file in "${image}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Set Test Variable    ${fingerprint_file}    ${mount_destination}/resin-root.fingerprint
    Create Directory    ${mount_destination}
    Mount "/dev2/loop${LOOPDEVICE}p2" on "${mount_destination}"
    File Should Exist   ${fingerprint_file}     msg=Couldn't find resin-root.fingerprint file in ${mount_destination}
    ${content} =  Get File  ${fingerprint_file}
    @{lines} =  Split To Lines  ${content}
    : FOR   ${line}     IN  @{lines}
    \   @{words} =  Split String    ${line}     ${SPACE}
    \   ${First} =  Get From List   ${words}    0
    \   ${Second} =  Get From List  ${words}    2
    \   ${md5sum} =  Run Process    md5sum ${mount_destination}/${Second} | awk '{print $1}'     shell=yes
    \   Should Contain     ${First}   ${md5sum.stdout}    msg=${mount_destination}${Second} has MD5=${md5sum.stdout} when it should be ${First}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "/dev2/loop${LOOPDEVICE}"

Get host OS version of "${image}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Set Test Variable    ${path_to_os_version}   ${mount_destination}/etc/os-release
    Create Directory    ${mount_destination}
    Mount "/dev2/loop${LOOPDEVICE}p2" on "${mount_destination}"
    ${result} =  Run Process    cat ${path_to_os_version} | grep VERSION | head -1 | cut -d '"' -f 2    shell=yes
    Process ${result}
    Should Not Be Empty     ${result.stdout}    msg="Could not get OS version from ${path_to_os_version}"
    [Return]    ${result.stdout}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "/dev2/loop${LOOPDEVICE}"

File list "@{files_list}" does not exist in "${mount_destination}"
    : FOR   ${files_line}     IN  @{files_list}
    \   File Should Not Exist  ${mount_destination}${files_line}  msg="Backup file ${files_line} found on the rootfs that should not exist."

Enable getty service on "${image}" for "${device_type}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Create Directory    ${mount_destination}
    Mount "/dev2/loop${LOOPDEVICE}p2" on "${mount_destination}"
    Remove Directory    /tmp/enable_getty_service    recursive=True
    ${result} =  Run Process    git clone https://github.com/resin-os/serial-it.git /tmp/enable_getty_service    shell=yes
    Process ${result}
    ${result} =  Run Process    ./serial-it.sh --root-mountpoint ${mount_destination} -b ${device_type}     shell=yes   cwd=/tmp/enable_getty_service
    Process ${result}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "/dev2/loop${LOOPDEVICE}"

Check if service "${service}" is running using socket "${socket}"
    ${result} =  Run Process    echo "send root\nsend systemctl status ${service}" > minicom_script.sh    shell=yes    cwd=/tmp/enable_getty_service
    Process ${result}
    Run Process    minicom -D ${socket} -S /tmp/enable_getty_service/minicom_script.sh -C /tmp/enable_getty_service/minicom_output.txt    shell=yes   cwd=/tmp    timeout=1s
    File Should Not Be Empty    /tmp/enable_getty_service/minicom_output.txt
    ${result} =  Run Process    cat /tmp/enable_getty_service/minicom_output.txt | grep Active | cut -d ' ' -f 5    shell=yes
    Should Contain    ${result.stdout}    active
    Process ${result}

Check that backup files are not found in the ${image}
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Create Directory    ${mount_destination}
    Mount "/dev2/loop${LOOPDEVICE}p2" on "${mount_destination}"
    Set Test Variable    @{files_list}  /etc/shadow-     /etc/passwd-     /etc/group-   /etc/gshadow-
    File list "@{files_list}" does not exist in "${mount_destination}"
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "/dev2/loop${LOOPDEVICE}"

Check if kernel module loading works properly on ${device_uuid}
    ${address} =    Get public address of device "${device_uuid}"
    Wait Until Keyword Succeeds    6x    5s    Load "media" kernel module to device through "${address}"
    Wait Until Keyword Succeeds    6x    5s    Check if "media" kernel module is loaded through "${address}"

Unmount "${path}"
    ${result} =  Run Process    umount ${path}     shell=yes
    Process ${result}

Detach loop device "${path}"
    ${result} =  Run Process    losetup -d ${path}  shell=yes
    Process ${result}
