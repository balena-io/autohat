*** Settings ***
Documentation   Example test case
Resource  resources/resincli.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Prepare test environment
  Set Suite Variable    ${application_name}    qemux8664Autohat
Cleanup existing application
  Force delete application ${application_name}
Create Application
  Create application ${application_name} with device type qemux86-64
Push Application
  Push https://github.com/resin-io-projects/alpine-barebone.git to application ${application_name}
Delete Application
  Delete application ${application_name}
