*** Settings ***
Documentation   Resin device test example for raspberrypi3 - Please run with "--exitonerror"
Resource  resources/resincli.robot
Resource  resources/resinos.robot
Resource  resources/kernel.robot
Library   libraries/RigControl.py    device_id=%{rig_device_id}
Suite Teardown    Disable DUT

*** Test Cases ***
Preparing test environment
  Set Suite Variable    ${application_name}    %{application_name}
  Set Suite Variable    ${device_type}    %{device_type}
  Set Suite Variable    ${RESINRC_RESIN_URL}    %{RESINRC_RESIN_URL}
  Set Suite Variable    ${image}    %{image}
  File Should Exist     ${image}  msg="Provided images file does not exist"
  Set Suite Variable    ${application_repo}    https://github.com/resin-io/autohat-ondevice.git
  Set Suite Variable    ${application_commit}  e1f709a7bd1d4018acd1d6a69bef0a0b82f55085
  Resin login with email %{email} and password %{password}
  Set Suite Variable    ${rig_sd_card}    %{rig_sd_card}
  Disable DUT
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
Configuring image with application
  ${device_uuid} =    Configure "${image}" with "${application_name}"
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${result} =  Run Process    etcher --drive $(realpath ${rig_sd_card}) --yes ${image}  shell=yes
  Process ${result}
  Enable DUT
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device ${device_uuid} is online
Check that backup files are not found in the image
  Check that backup files are not found in the "${image}"
Git pushing to application
  Push "${application_repo}":"${application_commit}" to application "${application_name}"
Check if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Hello"
Check if kernel module loading works properly
  Check if kernel module loading works properly on "${device_uuid}"
Check if test environment variable is present
  Add ENV variable "Hello" with value "World" to application "${application_name}"
  Check if ENV variable "Hello" exists in application "${application_name}"
  Check if value of ENV variable is "World" in application "${application_name}"
  Remove ENV variable "Hello" from application "${application_name}"
Verify if host OS version of the image is same through resin cli
  Check if host OS version of device "${device_uuid}" is "${os_version}"
