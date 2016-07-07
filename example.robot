*** Settings ***
Documentation   Example test case
Resource  resources/resincli.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Prepare test environment
  Set Suite Variable    ${application_name}    qemux8664Autohat
  Set Suite Variable    ${deployment}    resinstaging
  Set Suite Variable    ${device_type}    qemux86-64
  Add new SSH key with name ${application_name}
Cleanup existing Application
  Force delete application ${application_name}
Create Application
  Create application ${application_name} with device type ${device_type}
Push Application
  Push https://github.com/resin-io-projects/alpine-barebone.git to application ${application_name}
