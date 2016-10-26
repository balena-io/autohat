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
    ${result} =  Run Process    resin whoami |sed '/USERNAME/!d' |sed 's/^.*USERNAME: //'   shell=yes
    Process ${result}
    Set Suite Variable    ${RESINUSER}    ${result.stdout}

Add new SSH key with name "${key_name}"
    Remove File    /root/.ssh/id_ecdsa
    ${result} =  Run Process    ssh-keygen -b 521 -t ecdsa -f /root/.ssh/id_ecdsa -N ''    shell=yes
    Process ${result}
    ${result} =  Run Process    resin keys |grep ${key_name} |cut -d ' ' -f 1   shell=yes
    Log   all output: ${result.stdout}
    Run Keyword If    '${result.stdout}' != 'NULL'    Run Process    resin key rm ${result.stdout} -y   shell=yes
    ${result} =  Run Process    resin key add ${key_name} /root/.ssh/id_ecdsa.pub   shell=yes
    Process ${result}

Create application "${application_name}" with device type "${device}"
    ${result} =  Run Process    resin app create ${application_name} --type\=${device}   shell=yes
    Process ${result}
    Should Match    ${result.stdout}    *Application created*

Delete application ${application_name}
    ${result} =  Run Process    resin app rm ${application_name} --yes    shell=yes
    Process ${result}

Force delete application "${application_name}"
    Run Keyword And Ignore Error    Delete application ${application_name}

Push "${git_url}":"${commit_hash}" to application "${application_name}"
    Remove Directory    tmp    recursive=True
    Create Directory    tmp
    ${result} =  Run Process    git clone ${git_url} ${application_name}   shell=yes    cwd=./tmp
    Process ${result}
    Set Environment Variable    RESINUSER    ${RESINUSER}
    ${result} =  Run Process    git remote add resin $RESINUSER@git.${RESINRC_RESIN_URL}:$RESINUSER/${application_name}.git    shell=yes    cwd=./tmp/${application_name}
    Process ${result}
    ${result} =  Run Process    git push resin ${commit_hash}:refs/heads/master    shell=yes    cwd=./tmp/${application_name}
    Process ${result}

Configure "${image}" with "${application_name}"
    File Should Exist     ${image}  msg="Provided images file does not exist"
    ${result_register} =  Run Process    resin device register ${application_name} | cut -d ' ' -f 4    shell=yes
    Process ${result_register}
    ${result} =  Run Process    echo -ne '\n' | resin os configure ${image} ${result_register.stdout}    shell=yes
    Process ${result}
    Return From Keyword    ${result_register.stdout}

Device ${device_uuid} is online
    ${result} =  Run Process    resin device ${device_uuid} | grep ONLINE    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    true

Device "${device_uuid}" log should contain "${value}"
    ${result} =  Run Process    resin logs ${device_uuid}    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${value}

Check if host OS version of device "${device_uuid}" is "${os_version}"
    ${result} =  Run Process    resin device ${device_uuid} | grep OS | rev | cut -d ' ' -f 1 | rev     shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${os_version}

Add ENV variable "${variable_name}" with value "${variable_value}" to application "${application_name}"
    ${result} =  Run Process    resin   env     add     ${variable_name}    ${variable_value}    -a  ${application_name}
    Process ${result}

Check if ENV variable "${variable_name}" exists in application "${application_name}"
    ${result_vars} =  Run Process    resin envs -a ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'   shell=yes
    Process ${result_vars}
    ${result_name} =  Run Process    echo "${result_vars.stdout}" | grep ${variable_name} | cut -d ' ' -f 2    shell=yes
    Process ${result_name}
    Should Contain    ${result_name.stdout}    ${variable_name}

Check if value of ENV variable is "${variable_value}" in application "${application_name}"
    ${result_vars} =  Run Process    resin envs -a ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'   shell=yes
    Process ${result_vars}
    ${result_value} =  Run Process    echo "${result_vars.stdout}" | grep ${variable_value} | cut -d ' ' -f 3    shell=yes
    Process ${result_value}
    Should Contain    ${result_value.stdout}    ${variable_value}

Remove ENV variable "${variable_name}" from application "${application_name}"
    ${result_vars} =  Run Process    resin envs -a ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'   shell=yes
    Process ${result_vars}
    ${result_id} =  Run Process    echo "${result_vars.stdout}" | grep ${variable_name} | cut -d ' ' -f 1    shell=yes
    Process ${result_id}
    ${result} =  Run Process    resin env rm ${result_id.stdout} --yes     shell=yes
    Process ${result}

Get public address of device "${device_uuid}"
    Run Process    resin device public-url enable ${device_uuid}    shell=yes
    ${result} =  Run Process    resin device public-url ${device_uuid}    shell=yes
    Process ${result}
    Return From Keyword    ${result.stdout}

Syncronize "${device_uuid}" to return "${message}"
    ${result} =  Run Process    sed -i '3i echo \"${message}\"' start.sh     shell=yes     cwd=./tmp/${application_name}
    Process ${result}
    ${result} =  Run Process    resin sync ${device_uuid} -s . -d /usr/src/app    shell=yes    cwd=./tmp/${application_name}
    Process ${result}

Check if resin sync works on "${device_uuid}"
    Syncronize "${device_uuid}" to return "Hello Resin Sync!"
    Device "${device_uuid}" log should contain "Hello Resin Sync!"

Check if setting environment variables works on "${application_name}"
    ${random} =   Evaluate    random.randint(0, 10000)    modules=random
    Add ENV variable "autohat${random}" with value "RandomValue" to application "${application_name}"
    Check if ENV variable "autohat${random}" exists in application "${application_name}"
    Check if value of ENV variable is "RandomValue" in application "${application_name}"
    Remove ENV variable "autohat${random}" from application "${application_name}"

Process ${result}
    Log   all output: ${result.stdout}
    Log   all output: ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0    msg="Command exited with error: ${result.stderr}"    values=False
