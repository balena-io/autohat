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

Verify resin-root.fingerprint in "${path}"
    File Should Exist   ${path}     msg=Couldn't find resin-root.fingerprint file in ${mount_destination}
    ${content} =  Get File  ${path}
    @{lines} =  Split To Lines  ${content}
    : FOR   ${line}     IN  @{lines}
    \   @{words} =  Split String    ${line}     ${SPACE}
    \   ${First} =  Get From List   ${words}    0
    \   ${Second} =  Get From List  ${words}    2
    \   ${md5sum} =  Run Process    md5sum ${mount_destination}/${Second} | awk '{print $1}'     shell=yes
    \   Should Contain     ${First}   ${md5sum.stdout}    msg=${mount_destination}${Second} has MD5=${md5sum.stdout} when it should be ${First})

Get the host OS version of the image
    ${result} =  Run Process    cat ${path_to_os_version} | grep VERSION | head -1 | cut -d '"' -f 2    shell=yes
    Process ${result}
    [Return]    ${result.stdout}

File list "@{files_list}" does not exist in "${mount_destination}"
    : FOR   ${files_line}     IN  @{files_list}
    \   File Should Not Exist  ${mount_destination}${files_line}  msg="Backup file ${files_line} found on the rootfs that should not exist." 
    
Unmount "${path}"
    ${result} =  Run Process    umount ${path}     shell=yes
    Process ${result}

Detach loop device "${path}"
    ${result} =  Run Process    losetup -d ${path}  shell=yes
    Process ${result}
