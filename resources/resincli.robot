*** Settings ***
Documentation   This resource provides access to resin commands.
Library   Process

*** Variables ***

*** Keywords ***
CLI version is ${version}
  ${result} =   Run Process   resin   version
  Process ${result}
  Should Match    ${result.stdout}   ${version}

Create application ${application_name} with device type ${device}
  ${result} =   Run Process   resin   app   create    ${application_name}   --type\=${device}
  Process ${result}
  Should Match    ${result.stdout}   *Application created*

Delete application ${application_name}
  ${result} =   Run Process   resin   app   rm    ${application_name}   --yes
  Process ${result}

Process ${result}
  Log   all output: ${result.stdout}
  Log   all output: ${result.stderr}
  Should Be Equal As Integers  ${result.rc}    0    msg="resin cli exited with error"  values=False
