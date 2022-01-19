Change log
-----------

## v0.1.4 - 2021-04-13

* Empty commit to rebuild/publish docker image [ab77]

# v0.2.8
## (2022-01-19)

* Resolve fleet slug for git push [ab77]

# v0.2.7
## (2022-01-19)

* Update balena-cli parameters [ab77]

# v0.2.6
## (2022-01-19)

* Add resources and test plans [ab77]

# v0.2.5
## (2021-10-21)

* resinos.robot: Replace media module with mc [Alex Gonzalez]
* qemu.robot: Adjust qemu launch options to use an ahci drive [Alex Gonzalez]

# v0.2.4
## (2021-10-19)

* check for filename instead of using wildcard [rcooke-warwick]
* update fingerprint file path [rcooke-warwick]

# v0.2.3
## (2021-10-15)

* Track latest python3 [ab77]
* fixing python3.8 lib to generic python3 [fisehara]

# v0.2.2
## (2021-09-24)

* Remove redundant test [ab77]

# v0.2.1
## (2021-09-23)

* Add proxy port environment variable [ab77]

# v0.2.0
## (2021-06-03)

* Use the standalone balena-cli installation [Thodoris Greasidis]
* Update balena-cli to v12.44.17 [Thodoris Greasidis]
* Drop legacy resin sync test [Thodoris Greasidis]
* Add balena ssh test [Thodoris Greasidis]

# v0.1.8
## (2021-04-27)

* Test/empty [ab77]

# v0.1.7
## (2021-04-27)

* Exclude logs and images [ab77]

# v0.1.6
## (2021-04-14)

* Rebuild/empty [ab77]

# v0.1.5
## (2021-04-14)

* Add repo.yml to force Docker checks [ab77]

## v0.1.3 - 2021-04-13

* Implement retries when mounting loop device(s) [ab77]

## v0.1.2 - 2021-02-17

* Qemu: build qemu-5.2.0 from source [Kyle Harding]

## v0.1.1 - 2020-05-28

* Qemu.robot: Increase online check to 240 seconds [Florin Sarbu]

## v0.1.0 - 2020-04-22

* Upgrade e2e tests scaffold [ab77]

## v0.0.13 - 2019-11-18

* Add DEBUG on balena sync test [Michael Angelos Simos]

## v0.0.12 - 2019-09-27

* Dockerfile: Revert to v10.17.6 [Zubair Lutfullah Kakakhel]

## v0.0.11 - 2019-09-26

* Dockerfile: bump node, cli and etcher versions [Zubair Lutfullah Kakakhel]

## v0.0.10 - 2019-04-24

* Get journal logs from device [Horia Delicoti]

## v0.0.9 - 2019-03-27

* Bump dockerfile base from jessie to stretch [Zubair Lutfullah Kakakhel]

## v0.0.8 - 2019-03-04

* Ci: Publish to balena/autohat docker repo [Michael Angelos Simos]

## v0.0.7 - 2019-02-26

* Bump resin-cli to balena-cli@9.12.6 * Add functionality to check or remove configuration variables * r/resinos.robot: Modified test to disable RESIN_SUPERVISOR_DELTA rather than removing the configuration variable. [Horia Delicoti]

## v0.0.6 - 2019-01-14

* R/resinos.robot: Fix minicom command not send twice root command * get rid of the garbage in the output by waiting for the prompt [Horia Delicoti]

## v0.0.5 - 2018-10-18

* Resincli.robot: Fix version test after balenaOS rename [Andrei Gherzan]
* Add RESINRC_PROXY_URL [Kostas Lekkas]

## v0.0.4 - 2018-10-17

* Bump resin-cli to 7.10.6 [Kostas Lekkas]

## v0.0.3 - 2018-09-26

* Increase timeout of minicom script [Horia Delicoti]

## v0.0.2 - 2018-09-26

* Versionbot: Add versionbot files and config [Giovanni Garufi]
* Initial resinci config [Horia Delicoti]

## v0.0.1

* 	Fix keywords due to changes after balena implementation [Horia]
* 	Add test case to check that the device does not return the resin-vpn IP address [Horia]
*	Fix keyword that checks fingerprint file to work with 1.X resin image version [Horia]
*	Change Run Process to Run Buffered Process that logs stdout and stdin to a file instead of a PIPE [Praneeth]
*	Enable resin sync test from example QEMU and RaspberryPi test cases because it was fixed in Resin 2.0 [Horia]
*	Fix keyword for not checking correctly if a service was active [Horia]
*	Test case that verifies the OS fingerprint file on resin-boot partition [Horia]
*	Remove test for resin-info service starting [Will]
* 	Fix Host OS version to be agnostic to keywords appened after the OS version [Praneeth]
* 	Test case that provides a device to the application that already has delta enabled [Horia]
* 	Fixing keyword that fails if duplicate names are found in resin keys. Also, adding disclaimer as warning [Horia]
* 	Changing resin-cli version to v.5.2.4 [Horia]
* 	Fix Host OS Fingerprint test to work with both Resin OS 1.0 and 2.0 [Praneeth]
* 	Various fixes due to changes in operating system [Andrei]
* 	Rewrite test cases to keep consistency of its names [Horia]
* 	Modify losetup process in resinos.robot to prevent race conditions and add devtmpfs mounts when run with systemd [Praneeth]
* 	Modify RigControl Library to include support for the patch [Praneeth]
* 	Add udevd rules for enabling sd card reader symlink by board serial number [Praneeth]
* 	Bump etcher to v1.0.0-beta.18 [Praneeth]
* 	Fixing keyword that verifies delta to a running supervisor [Horia]
* 	Fixing keyword that did not push the correct commit [Horia]
* 	Fixing tests to fail properly if environment variables are not provided [Horia]
* 	Disable resin sync and resin delta tests from example QEMU and RaspberryPi test cases until they are fixed in Resin 2.0 [Praneeth]
* 	Pin version of Base image in Dockerfile and python libraries installed with pip [Praneeth]
* 	Unify instuctions for QEMU 64bit and 32bit images [Horia]
* 	Test case to verify delta to a running supervisor [Horia]
* 	Add CREATE_APPLICATION to enable/disable application tests in qemux86-64.robot, this will allow for easier integration with tests that dont need application creation [Praneeth]
* 	Re-Organize tests so that they are self contained and the Test Suites have minimal overhead [Praneeth]  
* 	Ensure that resin sync works [Horia]
* 	Add test case to verify if resin-info service is active [Horia]
* 	Switch to using the nuc-node as the base for the Dockerfile [Praneeth]
* 	Add support for Autohat Rig and add example RaspberryPi3 test file [Praneeth]
* 	Upgrade Resin CLI used to 4.5.0 [Praneeth]
* 	Add test case that verifies backup files [Horia]
* 	Add testcase for checking that loading a random kernel module works in a container [Tomás]
* 	Add test case that gets the host OS version of the image [Horia]
*	Add new test for checking if md5sum of the host OS changed compared to fingerprint file [Horia]
* 	Change the default application pushed ondevice to autohat-ondevice [Praneeth]
* 	Add support pushing a specific commit to the Push Keyword [Praneeth]
* 	Add new test for checking if host OS version of the image is same via resin cli [Horia]
* 	Add new test for checking application environment variable [Horia]
*	Fixed CLI version to 4.2 [Horia]
* 	Add support for devices without KVM virtualization [Tomás]
