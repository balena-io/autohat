*** Settings ***
Documentation    This resource provides access to balena commands.
Library   Process
Library   OperatingSystem
Library   RequestsLibrary

*** Variables ***

*** Keywords ***
Resin login with email "${email}" and password "${password}"
    ${result} =  Run Process    balena login --credentials --email ${email} --password ${password}    shell=yes    timeout=30sec
    Process ${result}
    ${result} =  Run Process    balena whoami |sed '/USERNAME/!d' |sed 's/^.*USERNAME: //'   shell=yes
    Process ${result}
    Set Suite Variable    ${RESINUSER}    ${result.stdout}
    ${result} =  Run Process    balena fleet ${application_name} | grep ^SLUG: | cut -c14-   shell=yes
    Process ${result}
    Set Suite Variable    ${FLEET}    ${result.stdout}

Add new SSH key with name "${key_name}"
    Remove File    /root/.ssh/id_ecdsa
    ${result} =  Run Process    ssh-keygen -b 521 -t ecdsa -f /root/.ssh/id_ecdsa -N ''    shell=yes
    Process ${result}
    ${word_count} =  Run Process    balena keys |grep -w ${key_name} |cut -d ' ' -f 1 | wc -l    shell=yes
    Process ${word_count}
    FOR    ${i}    IN RANGE    ${word_count.stdout}
        ${result} =  Run Process    balena keys |grep -w ${key_name} |cut -d ' ' -f 1 | head -1    shell=yes
        Log   all output: ${result.stdout}
        Run Process    balena key rm ${result.stdout} -y    shell=yes
    END
    ${result} =  Run Process    cat /root/.ssh/id_ecdsa.pub | balena key add "${key_name}"    shell=yes    timeout=60sec
    Process ${result}

Delete SSH key with name "${key_name}"
    ${result} =  Run Process    balena keys | grep -w ${key_name} | cut -d ' ' -f 1 | head -1    shell=yes
    Log   all output: ${result.stdout}
    Run Process    balena key rm ${result.stdout} -y    shell=yes
    Process ${result}

Create fleet "${fleet_name}" in org "${org}" with device type "${device}"
    ${result} =  Run Process    balena fleet create ${fleet_name} ---organization\=${org} --type\=${device}    shell=yes
    Process ${result}
    Should Match    ${result.stdout}    *Fleet created*

Delete fleet "${fleet_name}"
    ${result} =  Run Process    balena fleet rm ${fleet_name} --yes    shell=yes
    Process ${result}

Force delete fleet "${fleet_name}"
    Run Keyword And Ignore Error    Delete fleet "${fleet_name}"

Git clone "${git_url}" "${directory}"
    Remove Directory    ${directory}    recursive=True
    ${result} =  Run Process    git clone ${git_url} ${directory}    shell=yes
    Process ${result}

Git checkout "${commit_hash}" "${directory}"
    ${result} =  Run Process    git checkout ${commit_hash}    shell=yes    cwd=${directory}
    Process ${result}

Git push "${directory}" to application "${application_name}"
    Set Environment Variable    RESINUSER    ${RESINUSER}
    ${result} =  Run Process    git remote add balena $RESINUSER@git.${BALENARC_BALENA_URL}:${FLEET}.git    shell=yes    cwd=${directory}
    Process ${result}
    ${result} =  Run Buffered Process    git push balena HEAD:refs/heads/master    shell=yes    cwd=${directory}
    Process ${result}

Balena push "${directory}" to application "${application_name}"
    ${result} =  Run Buffered Process    balena push ${application_name}    shell=yes    cwd=${directory}
    Process ${result}

Configure "${image}" version "${os_version}" with "${application_name}"
    ${result_register} =  Run Process    balena device register ${application_name} | grep ${application_name} | cut -d ' ' -f 4    shell=yes
    Process ${result_register}
    ${result} =  Run Process    balena os configure ${image} --device ${result_register.stdout} --version ${os_version} --config-network ethernet --dev    shell=yes
    Process ${result}
    ${dns_server} =    Get Environment Variable    DNS_SERVER    default=empty
    ${dns_config} =    Run Keyword If    '${dns_server}' != 'empty'    Run Process    balena config write --drive "${image}" dnsServers "${dns_server}"    shell=yes
    Run Keyword If    '${dns_server}' != 'empty'    Process ${dns_config}
    Return From Keyword    ${result_register.stdout}

Get "${device_info}" of device "${device_uuid}"
    [Documentation]    Available values for argument ${device_info} are:
    ...                ID, DEVICE TYPE, STATUS, IS ONLINE, IP ADDRESS, APPLICATION NAME, UUID, COMMIT,
    ...                SUPERVISOR VERSION, IS WEB ACCESSIBLE, OS VERSION
    @{list} =  Create List    ID    DEVICE TYPE    STATUS    IS ONLINE    IP ADDRESS    APPLICATION NAME    UUID    COMMIT    SUPERVISOR VERSION    IS WEB ACCESSIBLE    OS VERSION
    Should Contain    ${list}    ${device_info}
    ${result} =  Run Keyword If    '${device_info}' == 'OS VERSION'    Run Process    balena device ${device_uuid} | sed -n -E -e 's/^.*(Resin OS|balenaOS) //p' | cut -d ' ' -f 1    shell=yes
    ...    ELSE
    ...    Run Process    balena device ${device_uuid} | grep -w "${device_info}" | cut -d ':' -f 2 | sed 's/ //g'    shell=yes
   Process ${result}
   RETURN    ${result.stdout}

Get "${application_info}" from fleet "${application_name}"
    [Documentation]    Available values for argument ${application_info} are:
    ...                ID, APP_NAME, DEVICE_TYPE, ONLINE_DEVICES, DEVICES_LENGTH
    &{dictionary} =  Create Dictionary    ID=1    APP_NAME=2    SLUG=3    DEVICE_TYPE=4    DEVICES_LENGTH=5    ONLINE_DEVICES=6
    ${result} =  Run Process    balena fleets | grep -w "${application_name}" | awk '{print $${dictionary.${application_info}}}'    shell=yes
    Process ${result}
    RETURN    ${result.stdout}

# FIXME: needs to select STATUS=success and IS FINAL=true
Get latest release from fleet "${application_name}"
    ${result} =  Run Process    balena releases "${application_name}" | head -n 2 | tail -n 1 | awk '{print $2}'    shell=yes
    Process ${result}
    RETURN    ${result.stdout}

# FIXME: needs to select STATUS=success and IS FINAL=true
Get previous release from fleet "${application_name}"
    ${result} =  Run Process    balena releases "${application_name}" | head -n 3 | tail -n 2 | tail -n 1 | awk '{print $2}'    shell=yes
    Process ${result}
    RETURN    ${result.stdout}

Pin device "${device_uuid}" to release "${release_uuid}"
    ${result} =  Run Process    balena device pin "${device_uuid}" "${release_uuid}"    shell=yes
    Process ${result}
    RETURN    ${result.stdout}

Device "${device_uuid}" is online
    ${result} =  Get "IS ONLINE" of device "${device_uuid}"
    Should Contain    ${result}    true

Device "${device_uuid}" is offline
    ${result} =  Get "IS ONLINE" of device "${device_uuid}"
    Should Contain    ${result}    false

Device "${device_uuid}" should be running commit ${commit}
    ${result} =  Get "COMMIT" of device "${device_uuid}"
    Should Contain    ${result}    ${commit}

Device "${device_uuid}" log should contain "${value}"
    ${result} =  Run Buffered Process    balena logs ${device_uuid}    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    ${value}

Device "${device_uuid}" log should not contain "${value}"
    ${result} =  Run Buffered Process    balena logs ${device_uuid}    shell=yes
    Process ${result}
    Should Not Contain    ${result.stdout}    ${value}

Check if host OS version of device "${device_uuid}" is "${os_version}"
    ${result} =  Get "OS VERSION" of device "${device_uuid}"
    Should Contain    ${result}    ${os_version}

Add ENV variable "${variable_name}" with value "${variable_value}" to application "${application_name}"
    ${result} =  Run Process    balena env add ${variable_name} ${variable_value} -f ${application_name}    shell=yes
    Process ${result}

Add variable "${variable_name}" with value "${variable_value}" to "${type}" "${id}"
    ${result} =  Run Process    balena env add ${variable_name} ${variable_value} --${type} ${id}    shell=yes
    Process ${result}

Check if "${option}" variable "${variable_name}" with value "${variable_value}" exists in application "${application_name}"
    [Documentation]    Available values for argument ${option} are: ENV, CONFIG
    @{list} =  Create List    ENV    CONFIG
    Should Contain    ${list}    ${option}
    ${result_env} =  Run Keyword If    '${option}' == 'ENV'    Run Process    balena envs -f ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'    shell=yes
    ...    ELSE
    ...    Run Process    balena envs --config -f ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'    shell=yes
    Process ${result_env}
    ${result} =  Run Process    echo "${result_env.stdout}" | grep ${variable_name} | grep " ${variable_value}"    shell=yes
    Process ${result}

Check if "${option}" variable "${variable_name}" with value "${variable_value}" exists on "${type}" "${id}"
    [Documentation]    Available values for argument ${option} are: ENV, CONFIG
    @{list} =  Create List    ENV    CONFIG
    Should Contain    ${list}    ${option}
    ${result} =  Run Keyword If    '${option}' == 'ENV'    Run Process    balena envs --${type} ${id} --json | jq 'any(.[]; .name \=\= "${variable_name}" and .value \=\= "${variable_value}")' | grep true    shell=yes
    ...    ELSE
    ...    Run Process    balena envs --config --${type} ${id} --json | jq 'any(.[]; .name \=\= "${variable_name}" and .value \=\= "${variable_value}")' | grep true    shell=yes
    Process ${result}

Remove "${option}" variable "${variable_name}" from application "${application_name}"
    [Documentation]    Available values for argument ${option} are: ENV, CONFIG
    @{list} =  Create List    ENV    CONFIG
    Should Contain    ${list}    ${option}
    ${result_vars} =  Run Keyword If    '${option}' == 'ENV'    Run Process    balena envs -f ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'    shell=yes
    ...    ELSE
    ...    Run Process    balena envs --config -f ${application_name} | sed '/ID[[:space:]]*NAME[[:space:]]*VALUE/,$!d'   shell=yes
    Process ${result_vars}
    ${result_id} =  Run Process    echo "${result_vars.stdout}" | grep ${variable_name} | cut -d ' ' -f 1    shell=yes
    Process ${result_id}
    ${result} =  Run Process    balena env rm ${result_id.stdout} --yes     shell=yes
    Process ${result}

"${item}" public URL for device "${device_uuid}"
    [Documentation]    Available items for argument ${item} are:
    ...                enable, disable, status, get
    @{list} =  Create List    enable    disable    status    get
    Should Contain    ${list}    ${item}
    ${result} =  Run Keyword If    '${item}' == 'get'    Run Process    balena device public-url ${device_uuid}    shell=yes
    ...    ELSE
    ...    Run Process    balena device public-url ${device_uuid} --${item}    shell=yes
    Process ${result}
    RETURN    ${result.stdout}

Get "${url}" with expected status "${status}"
    [Documentation]    https://docs.robotframework.org/docs/different_libraries/requests
    ${response} =  GET    ${url}  expected_status=${status}
    RETURN    ${response}

Check if SSH works on "${device_uuid}"
    ${result} =  Run Buffered Process    DEBUG=* echo "exit;" | balena ssh ${device_uuid} --port ${proxy_ssh_port}    shell=yes
    Process ${result}
    Should Contain    ${result.stdout}    Welcome to balenaOS

Check if setting environment variables works on "${application_name}"
    ${random} =   Evaluate    random.randint(0, 10000)    modules=random
    Add ENV variable "autohat${random}" with value "RandomValue" to application "${application_name}"
    Check if "ENV" variable "autohat${random}" with value "RandomValue" exists in application "${application_name}"
    Remove "ENV" variable "autohat${random}" from application "${application_name}"

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
    ${result} =  Run Buffered Process    git log | grep commit | head -1 | cut -d ' ' -f 2    shell=yes    cwd=${directory}
    Process ${result}
    RETURN    ${result.stdout}

Check that "${device_uuid}" does not return "${interface}" IP address through API using socket "${socket}"
    ${ip_address} =    Get "${interface}" IP address using socket "${socket}"
    ${ip_address_device} =    Get "IP ADDRESS" of device "${device_uuid}"
    Should Not Contain    ${ip_address_device}    ${ip_address}    msg=Device ${device_uuid} is returning the ${interface} IP address

Shutdown resin device "${device_uuid}"
    ${result} =  Run Buffered Process    balena device shutdown ${device_uuid}    shell=yes
    Process ${result}

Run Buffered Process
    [Arguments]    ${command}    ${shell}    ${cwd}=${EXECDIR}    ${timeout}=30min
    ${random} =  Evaluate    random.randint(0, sys.maxsize)    modules=random, sys
    ${result} =  Run Process    ${command}    shell=${shell}    cwd=${cwd}    timeout=${timeout}    stdout=/tmp/autohat.${random}.stdout    stderr=/tmp/autohat.${random}.stderr
    RETURN    ${result}

Process ${result}
    Log   all output: ${result.stdout}
    Log   all output: ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0    msg="Command exited with error: ${result.stderr}"    values=False
