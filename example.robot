*** Settings ***
Documentation   Sample Resin device test cases
Resource  resources/resincli.robot
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
Pushing application
  Push ${application_repo} to application ${application_name}
