*** Settings ***
Documentation   Example test case
Resource  resources/resincli.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Check resin-cli version
  CLI version is 4.0.3
Create Application
  Create application hello with device type raspberrypi2
Delete Application
  Delete application hello
