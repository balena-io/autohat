*** Settings ***
Documentation   Sample Resin device test cases, requires KVM.
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
  Configure ${image} with ${application_name}
Running image
  Run Keyword if  '${PREV_TEST_STATUS}'=='FAIL'  Fatal Error  msg="Skipping since configuring image failed."
  ${handle} =    Run ${image} with 512 MB memory and 4 cpus
  Set Suite Variable    ${device_handle}    ${handle}
Pushing application
  Run Keyword if  '${PREV_TEST_STATUS}'=='FAIL'  Fatal Error  msg="Skipping since running image failed."
  Push ${application_repo} to application ${application_name}
Wait till Qemu is killed or 5 minutes
  Wait For Process    handle=${device_handle}    timeout=600s    on_timeout=terminate
