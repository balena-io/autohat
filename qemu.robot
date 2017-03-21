*** Settings ***
Documentation   Resin device test for QEMU device
Resource  resources/resincli.robot
Resource  resources/qemu.robot
Resource  resources/resinos.robot
Resource  resources/kernel.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Preparing test environment
  Set Suite Variable    ${application_name}    %{application_name}
  Should Not Be Empty   ${application_name}    msg=application_name variable cannot be blank
  Set Suite Variable    ${device_type}    %{device_type}
  Set Suite Variable    ${RESINRC_RESIN_URL}    %{RESINRC_RESIN_URL}
  Set Suite Variable    ${image}    %{image}
  File Should Exist     ${image}  msg="Provided images file does not exist"
  Set Suite Variable    ${application_repo}    https://github.com/resin-io/autohat-ondevice.git
  Set Suite Variable    ${application_commit}  430cbe53d5582a03a503357e7cfde90d3aa8aee2
  Resin login with email "%{email}" and password "%{password}"
  ${create_application} =    Get Environment Variable    CREATE_APPLICATION    default=True
  Set Suite Variable    ${create_application}    ${create_application}
Adding new SSH key
  Add new SSH key with name "${application_name}"
Deleting application if it already exists
  Run Keyword If    '${create_application}' == 'True'    Force delete application "${application_name}"
Creating application
  Run Keyword If    '${create_application}' == 'True'    Create application "${application_name}" with device type "${device_type}"
Checking host OS fingerprint file
  Check host OS fingerprint file in "${image}"
Getting host OS version of the image
  ${return_os_version} =    Get host OS version of "${image}"
  Set Suite Variable    ${os_version}   ${return_os_version}
Enabling getty service on the image
  Enable getty service on "${image}" for "${device_type}"
Configuring image with application
  ${device_uuid} =    Configure "${image}" with "${application_name}"
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${handle} =    Run "${image}" with "512" MB memory "4" cpus and "/tmp/console.sock" serial port
  Set Suite Variable    ${device_qemu_handle}    ${handle}
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device "${device_uuid}" is online
Checking if resin-info@tty1.service is active
  Check if service "resin-info@tty1.service" is running using socket "unix\#/tmp/console.sock"
Git pushing to application
  Git clone "${application_repo}" "/tmp/${application_name}"
  Git checkout "${application_commit}" "/tmp/${application_name}"
  Git push "/tmp/${application_name}" to application "${application_name}"
Checking if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Hello"
Checking if kernel module loading works
  Check if kernel module loading works on "${device_uuid}"
#Checking delta to a running supervisor
#  Check enabling supervisor delta on "${application_name}"
#Checking if resin sync works
#  Check if resin sync works on "${device_uuid}"
Checking if setting environment variable works
  Check if setting environment variables works on "${application_name}"
Checking if host OS version of the image is same through resin cli
  Check if host OS version of device "${device_uuid}" is "${os_version}"
Checking if online / offline toggle is being reflected properly
  Shutdown resin device "${device_uuid}"
  Wait Until Keyword Succeeds    6x    5s    Device "${device_uuid}" is offline
  Wait For Process    handle=${device_qemu_handle}    timeout=30s    on_timeout=terminate
  ${handle} =    Run "${image}" with "512" MB memory "4" cpus and "/tmp/console.sock" serial port
  Set Suite Variable    ${device_qemu_handle}    ${handle}
  Wait Until Keyword Succeeds    6x    10s    Device "${device_uuid}" is online
Waiting till Qemu is killed or 30 seconds
  Shutdown resin device "${device_uuid}"
  Wait Until Keyword Succeeds    6x    5s    Device "${device_uuid}" is offline
  Wait For Process    handle=${device_qemu_handle}    timeout=30s    on_timeout=terminate
Checking that backup files are not found in the image
  Check that backup files are not found in the "${image}"
