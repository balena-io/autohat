*** Settings ***
Documentation   Example test case
Resource  resources/resincli.robot
Suite Teardown    Terminate All Processes    kill=True

*** Test Cases ***
Check resin-cli version
  CLI version is 4.0.3
Create Application
  Create application hello with device type nuc
Push Application
  Push git@github.com:resin-io-projects/alpine-barebone.git to application hello
Delete Application
  Delete application hello
