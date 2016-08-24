*** Settings ***
Documentation   Resin device test for qemux86-64 device, requires KVM - Please run with "--exitonerror"
Resource  resources/resincli.robot
Resource  resources/qemux86-64.robot
Resource  resources/resinos.robot
Resource  resources/kernel.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Preparing test environment
  Set Suite Variable    ${application_name}    %{application_name}
  Set Suite Variable    ${device_type}    %{device_type}
  Set Suite Variable    ${RESINRC_RESIN_URL}    %{RESINRC_RESIN_URL}
  Set Suite Variable    ${image}    %{image}
  File Should Exist     ${image}  msg="Provided images file does not exist"
  Set Suite Variable    ${application_repo}    https://github.com/resin-io/autohat-ondevice.git
  Set Suite Variable    ${application_commit}  dc610a169f4776b1e479d0aa6c5b3da4fdd113b6
  Resin login with email %{email} and password %{password}
  Set Suite Variable    ${mount_destination}    /mnt
  Set Suite Variable    ${host_os_partition}    2
  Set Suite Variable    ${path_to_fingerprint}  ${mount_destination}/resin-root.fingerprint
  Set Suite Variable    ${path_to_os_version}   ${mount_destination}/etc/os-release
  Set Suite Variable    @{backup_list}  /etc/shadow-     /etc/passwd-     /etc/group-   /etc/gshadow-
Adding new SSH key
  Add new SSH key with name ${application_name}
Deleting application if it already exists
  Force delete application ${application_name}
Creating application
  Create application ${application_name} with device type ${device_type}
Check host OS fingerprint file
  ${LOOPDEVICE} =   Set up loop device for "${image}"
  Set Suite Variable    ${path_to_loop}    /dev2/loop${LOOPDEVICE}
  Mount "${path_to_loop}p${host_os_partition}" on "${mount_destination}"
  Verify resin-root.fingerprint in "${path_to_fingerprint}"
  Unmount "${mount_destination}"
  Detach loop device "${path_to_loop}"
Get host OS version of the image
  ${LOOPDEVICE} =   Set up loop device for "${image}"
  Set Suite Variable    ${path_to_loop}    /dev2/loop${LOOPDEVICE}
  Mount "${path_to_loop}p${host_os_partition}" on "${mount_destination}"
  ${return_os_version} =    Get the host OS version of the image
  Set Suite Variable    ${os_version}   ${return_os_version}
  Unmount "${mount_destination}"
  Detach loop device "${path_to_loop}"
Configuring image with application
  ${device_uuid} =    Configure ${image} with ${application_name}
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${handle} =    Run ${image} with 512 MB memory and 4 cpus
  Set Suite Variable    ${device_qemu_handle}    ${handle}
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device ${device_uuid} is online
Check backup files 
  ${LOOPDEVICE} =   Set up loop device for "${image}"
  Set Suite Variable    ${path_to_loop}    /dev2/loop${LOOPDEVICE}
  Mount "${path_to_loop}p${host_os_partition}" on "${mount_destination}"
  Verify backup files 
  Unmount "${mount_destination}"
  Detach loop device "${path_to_loop}"
Git pushing to application
  Push ${application_repo}:${application_commit} to application ${application_name}
Check if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device ${device_uuid} log should contain Hello
Check if kernel module is loaded (Trying every 5s)
  ${address} =    Get public address of device ${device_uuid}
  Wait Until Keyword Succeeds    6x    5s    Load media kernel module to device through ${address}
  Wait Until Keyword Succeeds    6x    5s    Check if media kernel module is loaded through ${address}
Check if test environment variable is present
  Add ENV variable Hello with value World to application ${application_name}
  Check if ENV variable Hello exists in application ${application_name}
  Check if value of ENV variable is World in application ${application_name}
  Remove ENV variable Hello from application ${application_name}
Verify if host OS version of the image is same through resin cli
  Check if host OS version of device ${device_uuid} is ${os_version}
#Wait till Qemu is killed or 10 minutes
#  Wait For Process    handle=${device_qemu_handle}    timeout=600s    on_timeout=terminate
