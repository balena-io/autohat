*** Settings ***
Documentation    This resource provides access to host OS.
Library   Process
Library   OperatingSystem
Library   String
Library   Collections

*** Variables ***

*** Keywords ***
Set up loop device for "${path_to_image}"
    ${result} =  Run Process    losetup --show --find --partscan ${path_to_image}    shell=yes
    Process ${result}
    Should Not Be Empty     ${result.stdout}   msg="Couldn't find the loop device"
    ${LOOPDEVICE} =  Replace String    ${result.stdout}    dev    dev2
    [Return]    ${LOOPDEVICE}

Mount "${path}" on "${mount_destination}"
    ${result} =  Run Process    mount ${path} ${mount_destination}    shell=yes
    Process ${result}

Check host OS fingerprint file in "${image}" on "${partition}" partition
    [Documentation]    Available items for argument ${partition} are: boot, root
    &{dict} =  Create Dictionary    boot=1    root=2
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Run Keyword If    '${partition}' == 'boot'    Set Test Variable    ${fingerprint_file}    ${mount_destination}/resinos.fingerprint
    Create Directory    ${mount_destination}
    Mount "${LOOPDEVICE}p${dict.${partition}}" on "${mount_destination}"
    ${path_to_home_p2} =    Run Keyword If    '${partition}' == 'root'    Run Process    find ${mount_destination} -name "home"    shell=yes
    ${path_to_fingerprint_p2}    ${last} =    Run Keyword If    '${partition}' == 'root'    Split String From Right    ${path_to_home_p2.stdout}    /    1
    Run Keyword If    '${partition}' == 'root'    Set Test Variable   ${fingerprint_p2_resin-boot}    ${path_to_fingerprint_p2}/resin-boot/resinos.fingerprint
    Run Keyword If    '${partition}' == 'root'    Set Test Variable    ${fingerprint_file}    ${path_to_fingerprint_p2}/resinos.fingerprint
    Run Keyword If    '${partition}' == 'root'    File Should Exist    ${fingerprint_p2_resin-boot}   msg=Couldn't find ${fingerprint_p2_resin-boot}
    ${content_fingerprint_p2_resin-boot} =    Run Keyword If    '${partition}' == 'root'    Get File    ${fingerprint_p2_resin-boot}
    File Should Exist   ${fingerprint_file}     msg=Couldn't find ${fingerprint_file} in ${mount_destination}
    ${content} =  Get File  ${fingerprint_file}
    Run Keyword If    '${partition}' == 'boot'    Set Global Variable    ${fingerprint_content_partition1}    ${content}
    Run Keyword If    '${partition}' == 'root'    Should Contain    ${fingerprint_content_partition1}    ${content_fingerprint_p2_resin-boot}
    @{lines} =  Split To Lines  ${content}
    : FOR   ${line}     IN  @{lines}
    \   ${first} =  Fetch From Left    ${line}    ${SPACE}
    \   ${second} =  Fetch From Right    ${line}    ${SPACE}
    \   ${md5sum} =  Run Process    md5sum ${mount_destination}${second} | awk '{print $1}'    shell=yes
    \   Should Contain     ${first}   ${md5sum.stdout}    msg=${mount_destination}${second} has MD5=${md5sum.stdout} when it should be ${first}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "${LOOPDEVICE}"

Get host OS version of "${image}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Create Directory    ${mount_destination}
    Mount "${LOOPDEVICE}p1" on "${mount_destination}"
    ${find_path_to_os_version} =  Run Process    find ${mount_destination} -name "os-release"    shell=yes
    Process ${find_path_to_os_version}
    Set Test Variable    ${path_to_os_version}   ${find_path_to_os_version.stdout}
    ${result} =  Run Process    cat ${path_to_os_version} | grep VERSION | head -1 | cut -d '"' -f 2    shell=yes
    Process ${result}
    Should Not Be Empty     ${result.stdout}    msg="Could not get OS version from ${path_to_os_version}"
    [Return]    ${result.stdout}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "${LOOPDEVICE}"

File list "@{files_list}" does not exist in "${mount_destination}"
    : FOR   ${files_line}     IN  @{files_list}
    \   File Should Not Exist  ${mount_destination}${files_line}  msg="Backup file ${files_line} found on the rootfs that should not exist."

Enable getty service on "${image}" for "${device_type}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Create Directory    ${mount_destination}
    Mount "${LOOPDEVICE}p2" on "${mount_destination}"
    ${path_to_home} =    Run Process    find ${mount_destination} -name "home"    shell=yes
    Process ${path_to_home}
    ${mount_destination_to_home}    ${mount_destination_to_home_last}=    Split String From Right    ${path_to_home.stdout}    /    1
    Remove Directory    /tmp/enable_getty_service    recursive=True
    ${result} =  Run Process    git clone https://github.com/resin-os/serial-it.git /tmp/enable_getty_service    shell=yes
    Process ${result}
    ${result} =  Run Process    ./serial-it.sh --root-mountpoint ${mount_destination_to_home} -b ${device_type}    shell=yes    cwd=/tmp/enable_getty_service
    Process ${result}
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "${LOOPDEVICE}"

Check if service "${service}" is running using socket "${socket}"
    ${result} =  Run Process    echo "send root\nsend systemctl status ${service}" > minicom_script_service.sh    shell=yes    cwd=/tmp/enable_getty_service
    Process ${result}
    Run Process    minicom -D ${socket} -S /tmp/enable_getty_service/minicom_script_service.sh -C /tmp/enable_getty_service/minicom_output_service.txt    shell=yes    cwd=/tmp    timeout=1s
    ${result} =  Run Process    cat /tmp/enable_getty_service/minicom_output_service.txt    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${service}    msg=Could not get status of "${service}"
    Should Contain    ${result.stdout}    Active: active (running)    msg="${service}" is not active
    [Teardown]    Run Keyword    Remove Files    /tmp/enable_getty_service/minicom_script_service.sh    /tmp/enable_getty_service/minicom_output_service.txt

Check that backup files are not found in the "${image}"
    ${LOOPDEVICE} =   Set up loop device for "${image}"
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Set Test Variable    ${mount_destination}    /tmp/${random}
    Create Directory    ${mount_destination}
    Mount "${LOOPDEVICE}p2" on "${mount_destination}"
    Set Test Variable    @{files_list}  /etc/shadow-     /etc/passwd-     /etc/group-   /etc/gshadow-
    File list "@{files_list}" does not exist in "${mount_destination}"
    [Teardown]    Run Keywords    Unmount "${mount_destination}"
    ...           AND             Remove Directory    ${mount_destination}    recursive=True
    ...           AND             Detach loop device "${LOOPDEVICE}"

Check if kernel module loading works on "${device_uuid}"
    "enable" public URL for device "${device_uuid}"
    ${result} =  "status" public URL for device "${device_uuid}"
    Should Contain    ${result}    true
    ${address} =  "get" public URL for device "${device_uuid}"
    Wait Until Keyword Succeeds    6x    5s    Load "media" kernel module to device through "${address}"
    Wait Until Keyword Succeeds    6x    5s    Check if "media" kernel module is loaded through "${address}"
    [Teardown]    Run Keyword    "disable" public URL for device "${device_uuid}"

Run "${image}" on "${application_name}" with delta already enabled
    ${random} =   Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Add ENV variable "RESIN_SUPERVISOR_DELTA" with value "1" to application "${application_name}"
    ${tmp_device_uuid} =    Configure "${image}" with "${application_name}"
    ${handle} =    Run "${image}" with "512" MB memory "2" cpus and "/tmp/console${random}.sock" serial port
    Wait Until Keyword Succeeds    12x    5s    Device "${tmp_device_uuid}" is online
    Wait Until Keyword Succeeds    60x    30s    Device "${tmp_device_uuid}" log should contain "Hello"
    Check if "CONFIG" variable "RESIN_SUPERVISOR_DELTA" with value "1" exists in application "${application_name}"
    Add ENV variable "RESIN_SUPERVISOR_DELTA" with value "0" to application "${application_name}"
    Shutdown resin device "${tmp_device_uuid}"
    Wait Until Keyword Succeeds    12x    5s    Device "${tmp_device_uuid}" is offline
    Wait For Process    handle=${handle}    timeout=30s    on_timeout=terminate
    [Teardown]    Run Process    rm /tmp/console${random}.sock    shell=yes

Get "${interface}" IP address using socket "${socket}"
    ${result} =  Run Process    echo "send root\nexpect \"#\"\nsend ifconfig ${interface}" > minicom_script_${interface}.sh    shell=yes    cwd=/tmp/enable_getty_service
    Process ${result}
    Run Process    minicom -D ${socket} -S enable_getty_service/minicom_script_${interface}.sh -C enable_getty_service/minicom_output_${interface}.txt    shell=yes    cwd=/tmp    timeout=10s
    ${result} =  Run Process    cat /tmp/enable_getty_service/minicom_output_${interface}.txt    shell=yes
    Process ${result}
    Should Not Contain    ${result.stdout}    ${interface}: error fetching interface    msg=Could not get "${interface}" IP address
    Should Contain    ${result.stdout}    ${interface}    msg=Could not get "${interface}" IP address
    Should Contain    ${result.stdout}    Link encap    msg=Could not get "${interface}" IP address
    ${result} =  Run Process    cat /tmp/enable_getty_service/minicom_output_${interface}.txt | grep "inet addr:" | cut -d ':' -f 2 | awk '{print $1}'    shell=yes
    Process ${result}
    Should Contain X Times    ${result.stdout}    .    3    msg=Could not get "${interface}" IP address
    [Return]    ${result.stdout}
    [Teardown]    Run Keyword    Remove Files    /tmp/enable_getty_service/minicom_output_${interface}.txt    /tmp/enable_getty_service/minicom_script_${interface}.sh

Unmount "${path}"
    ${result} =  Run Process    umount ${path}    shell=yes
    Process ${result}

Detach loop device "${path}"
    ${result} =  Run Process    losetup -d ${path}    shell=yes
    Process ${result}
