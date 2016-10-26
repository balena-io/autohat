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
  Set Suite Variable    ${application_commit}  232e26aad374b2afd19c5608663545c2430e2b15
  Set Suite Variable    ${serial-it_repo}      https://github.com/resin-os/serial-it.git
  Resin login with email %{email} and password %{password}
Adding new SSH key
  Add new SSH key with name "${application_name}"
Deleting application if it already exists
  Force delete application "${application_name}"
Creating application
  Create application "${application_name}" with device type "${device_type}"
Check host OS fingerprint file
  Check host OS fingerprint file in "${image}"
Get host OS version of the image
  ${return_os_version} =    Get host OS version of "${image}"
  Set Suite Variable    ${os_version}   ${return_os_version}
Enable getty service on the image
  Enable getty service on "${image}" for "${device_type}"
Configuring image with application
  ${device_uuid} =    Configure "${image}" with "${application_name}"
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${handle} =    Run "${image}" with "512" MB memory "4" cpus and "/tmp/console.sock" serial port
  Set Suite Variable    ${device_qemu_handle}    ${handle}
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device ${device_uuid} is online
Verify if resin-info@tty1.service is active
  Check if service "resin-info@tty1.service" is running using socket "unix\#/tmp/console.sock"
Check that backup files are not found in the image
  Check that backup files are not found in the ${image}
Git pushing to application
  Push "${application_repo}":"${application_commit}" to application "${application_name}"
Check if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Hello"
Check if kernel module is loaded (Trying every 5s)
  ${address} =    Get public address of device "${device_uuid}"
  Wait Until Keyword Succeeds    6x    5s    Load "media" kernel module to device through "${address}"
  Wait Until Keyword Succeeds    6x    5s    Check if "media" kernel module is loaded through "${address}"
Ensure resin sync works
  Syncronize "${device_uuid}" to return "Hello Resin Sync!"
  Device "${device_uuid}" log should contain "Hello Resin Sync!"
Check if test environment variable is present
  Add ENV variable "Hello" with value "World" to application "${application_name}"
  Check if ENV variable "Hello" exists in application "${application_name}"
  Check if value of ENV variable is "World" in application "${application_name}"
  Remove ENV variable "Hello" from application "${application_name}"
Verify if host OS version of the image is same through resin cli
  Check if host OS version of device "${device_uuid}" is "${os_version}"
#Wait till Qemu is killed or 10 minutes
#  Wait For Process    handle=${device_qemu_handle}    timeout=600s    on_timeout=terminate
