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
    ${result} =  Run Process    resin whoami |sed '/USERNAME/!d' |sed 's/^.*USERNAME: //'   shell=yes   cwd=./tmp
    Process ${result}
    Set Environment Variable    RESINUSER    ${result.stdout}
    ${result} =  Run Process    git remote add resin $RESINUSER@git.resin.io:$RESINUSER/${application_name}.git    shell=yes    cwd=./tmp/${application_name}
    Process ${result}
    ${result} =  Run Process    git push resin master    shell=yes    cwd=./tmp/${application_name}
    Process ${result}

Process ${result}
    Log   all output: ${result.stdout}
    Log   all output: ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0    msg="Command exited with error"    values=False
