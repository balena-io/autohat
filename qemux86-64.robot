*** Settings ***
Documentation   Resin device test for qemux86-64 device, requires KVM - Please run with "--exitonerror"
Resource  resources/resincli.robot
Resource  resources/qemux86-64.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Preparing test environment
  Set Suite Variable    ${application_name}    %{application_name}
  Set Suite Variable    ${device_type}    %{device_type}
  Set Suite Variable    ${RESINRC_RESIN_URL}    %{RESINRC_RESIN_URL}
  Set Suite Variable    ${image}    %{image}
  File Should Exist     ${image}  msg="Provided images file does not exist"
  Set Suite Variable    ${application_repo}    https://github.com/resin-io-projects/alpine-barebone.git
  Resin login with email %{email} and password %{password}
Adding new SSH key
  Add new SSH key with name ${application_name}
Deleting application if it already exists
  Force delete application ${application_name}
Creating application
  Create application ${application_name} with device type ${device_type}
Configuring image with application
  ${device_uuid} =    Configure ${image} with ${application_name}
  Set Suite Variable    ${device_uuid}    ${device_uuid}
Running image
  ${handle} =    Run ${image} with 512 MB memory and 4 cpus
  Set Suite Variable    ${device_qemu_handle}    ${handle}
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device ${device_uuid} is online
Git pushing to application
  Push ${application_repo} to application ${application_name}
Check if device is running the pushed application (Tries for 300 s)
  Wait Until Keyword Succeeds    30x    10s    Device ${device_uuid} log should contain Hello
Check if test environment variable is present
  Add ENV variable Hello with value World to application ${application_name}
  Check if ENV variable Hello exists in application ${application_name}
  Check if value of ENV variable is World in application ${application_name}
  Remove ENV variable Hello from application ${application_name}
#Wait till Qemu is killed or 10 minutes
#  Wait For Process    handle=${device_qemu_handle}    timeout=600s    on_timeout=terminate
