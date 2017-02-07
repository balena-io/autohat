*** Settings ***
Documentation    This resource provides access to resin commands.
Library   Process
Library   OperatingSystem

*** Variables ***

*** Keywords ***
Resin login with email "${email}" and password "${password}"
    ${result} =  Run Process    resin login --credentials --email ${email} --password ${password}    shell=yes    timeout=30sec
    Process ${result}
    ${result} =  Run Process    resin whoami |sed '/USERNAME/!d' |sed 's/^.*USERNAME: //'   shell=yes
    Process ${result}
    Set Suite Variable    ${RESINUSER}    ${result.stdout}

Add new SSH key with name "${key_name}"
    Remove File    /root/.ssh/id_ecdsa
    ${result} =  Run Process    ssh-keygen -b 521 -t ecdsa -f /root/.ssh/id_ecdsa -N ''    shell=yes
    Process ${result}
    ${word_count} =  Run Process    resin keys |grep -w ${key_name} |cut -d ' ' -f 1 | wc -l    shell=yes
    Process ${word_count}
    :FOR    ${i}    IN RANGE    ${word_count.stdout}
    \    ${result} =  Run Process    resin keys |grep -w ${key_name} |cut -d ' ' -f 1 | head -1    shell=yes
    \    Log   all output: ${result.stdout}
    \    Run Process    resin key rm ${result.stdout} -y    shell=yes
    ${result} =  Run Process    resin key add ${key_name} /root/.ssh/id_ecdsa.pub   shell=yes
    Process ${result}

Create application "${application_name}" with device type "${device}"
    ${result} =  Run Process    resin app create ${application_name} --type\=${device}   shell=yes
    Process ${result}
    Should Match    ${result.stdout}    *Application created*

Delete application "${application_name}"
    ${result} =  Run Process    resin app rm ${application_name} --yes    shell=yes
    Process ${result}

Force delete application "${application_name}"
    Run Keyword And Ignore Error    Delete application "${application_name}"

Git clone "${git_url}" "${directory}"
    Remove Directory    ${directory}    recursive=True
    ${result} =  Run Process    git clone ${git_url} ${directory}    shell=yes
    Process ${result}

Git checkout "${commit_hash}" "${directory}"
    ${result} =  Run Process    git checkout ${commit_hash}    shell=yes    cwd=${directory}
    Process ${result}

Git push "${directory}" to application "${application_name}"
    Set Environment Variable    RESINUSER    ${RESINUSER}
    ${result} =  Run Process    git remote add resin $RESINUSER@git.${RESINRC_RESIN_URL}:$RESINUSER/${application_name}.git    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Process    git push resin HEAD:refs/heads/master    shell=yes    cwd=${directory}
    Process ${result}

Git push force "${directory}" to application "${application_name}"
    Set Environment Variable    RESINUSER    ${RESINUSER}
    ${result} =  Run Process    git remote add resin $RESINUSER@git.${RESINRC_RESIN_URL}:$RESINUSER/${application_name}.git    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Process    git push resin HEAD:refs/heads/master -f    shell=yes    cwd=${directory}
    Process ${result}

Configure "${image}" with "${application_name}"
    File Should Exist     ${image}  msg="Provided images file does not exist"
    ${result_register} =  Run Process    resin device register ${application_name} | cut -d ' ' -f 4    shell=yes
    Process ${result_register}
    ${result} =  Run Process    echo -ne '\n' | resin os configure ${image} ${result_register.stdout}    shell=yes
    Process ${result}
    Return From Keyword    ${result_register.stdout}

Device "${device_uuid}" is online
    ${result} =  Run Process    resin device ${device_uuid} | grep ONLINE    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    true

Device "${device_uuid}" is offline
    ${result} =  Run Process    resin device ${device_uuid} | grep ONLINE    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    false

Device "${device_uuid}" log should contain "${value}"
    ${result} =  Run Process    resin logs ${device_uuid}    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${value}

Device "${device_uuid}" log should not contain "${value}"
    ${result} =  Run Process    resin logs ${device_uuid}    shell=yes
    Process ${result}
    Should Not Contain    ${result.stdout}    ${value}

Check if host OS version of device "${device_uuid}" is "${os_version}"
    ${result} =  Run Process    resin device ${device_uuid} | grep OS | rev | cut -d ' ' -f 1 | rev     shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${os_version}

Add ENV variable "${variable_name}" with value "${variable_value}" to application "${application_name}"
    ${result} =  Run Process    resin env add ${variable_name} ${variable_value} -a ${application_name}    shell=yes
    Process ${result}

Check if ENV variable "${variable_name}" with value "${variable_value}" exists in application "${application_name}"
    ${result_env} =  Run Process    resin envs -a ${application_name} --verbose | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'    shell=yes
    Process ${result_env}
    ${result} =  Run Process    echo "${result_env.stdout}" | grep ${variable_name} | grep " ${variable_value}"    shell=yes
    Process ${result}

Remove ENV variable "${variable_name}" from application "${application_name}"
    ${result_vars} =  Run Process    resin envs -a ${application_name} --verbose | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'   shell=yes
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

Synchronize "${device_uuid}" to return "${message}"
    ${result} =  Run Process    sed -i '3i echo \"${message}\"' start.sh     shell=yes     cwd=/tmp/${application_name}
    Process ${result}
    ${result} =  Run Process    resin sync ${device_uuid} -s . -d /usr/src/app    shell=yes    cwd=/tmp/${application_name}
    Process ${result}

Check if resin sync works on "${device_uuid}"
    Synchronize "${device_uuid}" to return "Hello Resin Sync!"
    Device "${device_uuid}" log should contain "Hello Resin Sync!"

Check if setting environment variables works on "${application_name}"
    ${random} =   Evaluate    random.randint(0, 10000)    modules=random
    Add ENV variable "autohat${random}" with value "RandomValue" to application "${application_name}"
    Check if ENV variable "autohat${random}" with value "RandomValue" exists in application "${application_name}"
    Remove ENV variable "autohat${random}" from application "${application_name}"

Check enabling supervisor delta on "${application_name}"
    Add ENV variable "RESIN_SUPERVISOR_DELTA" with value "1" to application "${application_name}"
    Device "${device_uuid}" log should not contain "Killing application"
    ${random} =  Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Git clone "${application_repo}" "/tmp/${random}"
    Git checkout "${application_commit}" "/tmp/${random}"
    Add console output "Grettings World!" to "/tmp/${random}"
    ${last_commit} =    Get the last git commit from "/tmp/${random}"
    Git checkout "${last_commit}" "/tmp/${random}"
    Git push "/tmp/${random}" to application "${application_name}"
    Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Grettings World!"
    Check if ENV variable "RESIN_SUPERVISOR_DELTA" with value "1" exists in application "${application_name}"
    Remove ENV variable "RESIN_SUPERVISOR_DELTA" from application "${application_name}"
    [Teardown]    Run Keyword    Remove Directory    /tmp/${random}    recursive=True

Test update strategy "${update_strategy}" to application "${application_name}"
    Add ENV variable "RESIN_SUPERVISOR_UPDATE_STRATEGY" with value "${update_strategy}" to application "${application_name}"
    Check if ENV variable "RESIN_SUPERVISOR_UPDATE_STRATEGY" with value "${update_strategy}" exists in application "${application_name}"
    ${random} =  Evaluate    random.randint(0, sys.maxint)    modules=random, sys
    Git clone "${application_repo}" "/tmp/${random}"
    Git checkout "${application_commit}" "/tmp/${random}"
    Add console output "Update strategy: ${update_strategy}" to "/tmp/${random}"
    ${last_commit} =    Get the last git commit from "/tmp/${random}"
    Git checkout "${last_commit}" "/tmp/${random}"
    Run Keyword If    '${update_strategy}' == 'hand-over'    Run command "killall python" on device using socket "unix\#/tmp/console.sock"
    Run Keyword If    '${update_strategy}' == 'hand-over'    Add ENV variable "RESIN_SUPERVISOR_HANDOVER_TIMEOUT" with value "600" to application "${application_name}"
    Run Keyword If    '${update_strategy}' == 'hand-over'    Check if ENV variable "RESIN_SUPERVISOR_HANDOVER_TIMEOUT" with value "600" exists in application "${application_name}"
    Git push force "/tmp/${random}" to application "${application_name}"
    Wait Until Keyword Succeeds    30x    10s    Device "${device_uuid}" log should contain "Update strategy: ${update_strategy}"
    ${result} =  Run Keyword If    '${update_strategy}' == 'hand-over'    Run Process    resin logs ${device_uuid} | grep -B30 "Killing application" -s | tail -30 | grep -A30 "Updating config" | awk -F '\\)\ ' '{print $2'} > test_file_${update_strategy}    shell=yes    cwd=/tmp
    ...    ELSE    Run Process    resin logs ${device_uuid} | grep -B30 "Started application" -s | tail -30 | grep -A30 "Updating" | awk -F '\\)\ ' '{print $2'} > test_file_${update_strategy}    shell=yes    cwd=/tmp
    Process ${result}
    ${result} =  Run Process    python    /autohat/libraries/FileComparator.py    /autohat/libraries/template_${update_strategy}    /tmp/test_file_${update_strategy}    shell=yes
    Process ${result}
    [Teardown]    Run Keywords    Remove Directory    /tmp/${random}    recursive=True
    ...           AND             Remove ENV variable "RESIN_SUPERVISOR_UPDATE_STRATEGY" from application "${application_name}"
    ...           AND             Run Keyword If    '${update_strategy}' == 'hand-over'    Remove ENV variable "RESIN_SUPERVISOR_HANDOVER_TIMEOUT" from application "${application_name}"

Add console output "${message}" to "${directory}"
    ${result} =  Run Process    git config --global user.email "%{email}"    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Process    sed -ie 's/Hello World!/${message}/g' start.sh    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Process    git add .    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Process    git commit -m "Console message added: ${message}"    shell=yes    cwd=${directory}
    Process ${result}

Get the last git commit from "${directory}"
    ${result} =  Run Process    git log | grep commit | head -1 | cut -d ' ' -f 2    shell=yes    cwd=${directory}
    Process ${result}
    [Return]    ${result.stdout}

Shutdown resin device "${device_uuid}"
    ${result} =  Run Process    resin device shutdown ${device_uuid}    shell=yes
    Process ${result}

Process ${result}
    Log   all output: ${result.stdout}
    Log   all output: ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0    msg="Command exited with error: ${result.stderr}"    values=False
