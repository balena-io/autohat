*** Settings ***
Documentation    This resource provides access to kernel module loading commands.
Library   RequestsLibrary

*** Variables ***

*** Keywords ***
Load "${module}" kernel module to device through "${address}"
    Create Session    kernel    ${address}    verify=False
    ${request} =  Catenate    SEPARATOR=    /modprobe/    ${module}
    ${response} =  Get Request    kernel    ${request}
    Should Be Equal As Strings  ${response.status_code}  200

Check if "${module}" kernel module is loaded through "${address}"
    Create Session    lsmod    ${address}    verify=False
    ${response} =  Get Request    lsmod    /lsmod
    Should Be Equal As Strings  ${response.status_code}  200
    Should Contain    ${response.content}    ${module}
