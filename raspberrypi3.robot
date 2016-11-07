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
  Set Suite Variable    ${application_commit}  232e26aad374b2afd19c5608663545c2430e2b15
  Resin login with email "%{email}" and password "%{password}"
  Set Suite Variable    ${rig_sd_card}    %{rig_sd_card}
  ${create_application} =    Get Environment Variable    CREATE_APPLICATION    default=True
  Set Suite Variable    ${create_application}    ${create_application}
  Disable DUT
Adding new SSH key
  Add new SSH key with name "${application_name}"
Deleting application if it already exists
  Run Keyword If    '${create_application}' == 'True'    Force delete application "${application_name}"
Creating application
  Run Keyword If    '${create_application}' == 'True'    Create application "${application_name}" with device type "${device_type}"
Check host OS fingerprint file
  Check host OS fingerprint file in "${image}"
Get host OS version of the image
  ${return_os_version} =    Get host OS version of "${image}"
  Set Suite Variable    ${os_version}   ${return_os_version}
#Enable getty service on the image
#  Enable getty service on "${image}" for "${device_type}"
Configuring image with application
  ${device_uuid} =    Configure "${image}" with "${application_name}"
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${result} =  Run Process    etcher --drive $(realpath ${rig_sd_card}) --yes ${image}  shell=yes
  Process ${result}
  Enable DUT
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device "${device_uuid}" is online
#Verify if resin-info@tty1.service is active
#  Check if service "resin-info@tty1.service" is running using socket "unix\#/tmp/console.sock"
Git pushing to application
  Git clone "${application_repo}" "/tmp/${application_name}"
  Git checkout "${application_commit}" "/tmp/${application_name}"
  Git push "/tmp/${application_name}" to application "${application_name}"
Check if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Hello"
Check if kernel module loading works
  Check if kernel module loading works on "${device_uuid}"
Check delta to a running supervisor
  Check enabling supervisor delta on "${application_name}"
Check if resin sync works
  Check if resin sync works on "${device_uuid}"
Check if setting environment variable works
  Check if setting environment variables works on "${application_name}"
Verify if host OS version of the image is same through resin cli
  Check if host OS version of device "${device_uuid}" is "${os_version}"
#Check that backup files are not found in the image
#  Check that backup files are not found in the "${image}"
