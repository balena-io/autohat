*** Settings ***
Documentation    This resource provides access to resin commands.
Library   Process
Library   OperatingSystem

*** Variables ***

*** Keywords ***
CLI version is ${version}
    ${result} =  Run Process    resin version    shell=yes
    Process ${result}
    Should Match    ${result.stdout}    ${version}

Resin login with email ${email} and password ${password}
    ${result} =  Run Process    resin login --credentials --email ${email} --password ${password}    shell=yes
    Process ${result}
    ${result} =  Run Process    resin whoami |sed '/USERNAME/!d' |sed 's/^.*USERNAME: //'   shell=yes   cwd=./tmp
    Process ${result}
    Set Suite Variable    ${RESINUSER}    ${result.stdout}

Add new SSH key with name ${key_name}
    Remove File    /root/.ssh/id_ecdsa
    ${result} =  Run Process    ssh-keygen -b 521 -t ecdsa -f /root/.ssh/id_ecdsa -N ''    shell=yes
    Process ${result}
    ${result} =  Run Process    resin keys |grep ${key_name} |cut -d ' ' -f 1   shell=yes
    Log   all output: ${result.stdout}
    Run Keyword If    '${result.stdout}' != 'NULL'    Run Process    resin key rm ${result.stdout} -y   shell=yes
    ${result} =  Run Process    resin key add ${key_name} /root/.ssh/id_ecdsa.pub   shell=yes
    Process ${result}

Create application ${application_name} with device type ${device}
    ${result} =  Run Process    resin app create ${application_name} --type\=${device}   shell=yes
    Process ${result}
    Should Match    ${result.stdout}    *Application created*

Delete application ${application_name}
    ${result} =  Run Process    resin app rm ${application_name} --yes    shell=yes
    Process ${result}

Force delete application ${application_name}
    Run Keyword And Ignore Error    Delete application ${application_name}

Push ${git_url} to application ${application_name}
    Remove Directory    tmp    recursive=True
    Create Directory    tmp
    ${result} =  Run Process    git clone ${git_url} ${application_name}   shell=yes    cwd=./tmp
    Process ${result}
    Set Environment Variable    RESINUSER    ${RESINUSER}
    ${result} =  Run Process    git remote add resin $RESINUSER@git.${RESINRC_RESIN_URL}:$RESINUSER/${application_name}.git    shell=yes    cwd=./tmp/${application_name}
    Process ${result}
    ${result} =  Run Process    git push resin master    shell=yes    cwd=./tmp/${application_name}
    Process ${result}

Configure ${image} with ${application_name}
    File Should Exist     ${image}  msg="Provided images file does not exist"
    ${result} =  Run Process    resin device register ${application_name} | cut -d ' ' -f 4    shell=yes
    Process ${result}
    Set Suite Variable    ${device_uuid}    ${result.stdout}
    ${result} =  Run Process    resin os configure ${image} ${device_uuid}    shell=yes
    Process ${result}

Process ${result}
    Log   all output: ${result.stdout}
    Log   all output: ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0    msg="Command exited with error"    values=False
