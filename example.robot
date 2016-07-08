*** Settings ***
Documentation   Sample Resin device test for qemux86-64 device, requires KVM.
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
Verifying test environment
  Run Keyword if  '${PREV_TEST_STATUS}'=='FAIL'  Fatal Error  msg="Variables required for the test are missing."
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
  Run Keyword if  '${PREV_TEST_STATUS}'=='FAIL'  Fatal Error  msg="Skipping since configuring image failed."
  ${handle} =    Run ${image} with 512 MB memory and 4 cpus
  Set Suite Variable    ${device_qemu_handle}    ${handle}
Pushing application
  Run Keyword if  '${PREV_TEST_STATUS}'=='FAIL'  Fatal Error  msg="Skipping since running image failed."
  Push ${application_repo} to application ${application_name}
Checking if device comes online in 60s (Trying every 10s)
  Wait Until Keyword Succeeds    6x    10s    Device ${device_uuid} is online
Wait till Qemu is killed or 10 minutes
  Wait For Process    handle=${device_qemu_handle}    timeout=600s    on_timeout=terminate
