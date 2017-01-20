# Autohat - Automated Hardware Testing
### Technology preview

This projects hopes to make it easy to do automated testing of OS images. This test framework is based on [robotframework](http://robotframework.org). The included resources should make it easy to write tests in Gherkin.

The resources directory contains Robot Keyword helpers for ``resincli`` and hardware specific .robot files. This could be extended to add helpers for other cli tools and hardware. We have included a Dockerfile to setup the environment required to run the example.

### Instructions for running the example:

#### Running with QEMU device type

* Clone this repo and change your directory to it.

* Build the autohat container by running the following command:

  ``docker build -t autohat .``

* Build a resin-qemux86 or resin-qemux86-64 image from [https://github.com/resin-os/resin-qemu/](https://github.com/resin-os/resin-qemu/)

* Alternatively you can also download an uninitialized resin-qemux86 or resin-qemux86-64 image from resin by executing:

  ``resin os download qemux86 -o resin.img`` or

  ``resin os download qemux86-64 -o resin.img``

* Create a `env.list` with all the environment variables needed to run the tests - Please check `env.list.example` for a sample environment file.

    * **WARNING!** The application name given needs to be unique as the test suite will delete and recreate any existing application and key of the same name in the settings.

* Load the KVM module

* Execute the following to run an example test against the resin-qemux86 or resin-qemux86-64 image you just downloaded.

    ``docker run -it --rm -v <path_to_repo>:/autohat -v /dev/:/dev2 --privileged --env-file ./env.list autohat robot --exitonerror /autohat/qemu.robot``

#### Running with Autohat test rig on connected hardware (Example - Raspberry Pi 3)

* Clone this repo and change your directory to it.

* Build the autohat container by running the following command:

  ``docker build -t autohat .``

* Build the device specific resin image or download an uninitialized image from resin by executing:

  ``resin os download raspberrypi3 -o resin.img``

* Create a `env.list` with all the environment variables needed to run the tests - Please check `env.list.example` for a sample environment file.

	* Please make sure that the ``rig_device_id``, ``rig_sd_card`` match your rig's FTDI serial, the SD card path respectively

    * **WARNING!** The application name given needs to be unique as the test suite will delete and recreate any existing application and key of the same name in the settings.

* Execute the following to run an example test against the raspberrypi3 image you just downloaded.

    ``docker run -it --rm -v <path_to_repo>:/autohat -v /dev/:/dev2 --privileged --env-file ./env.list autohat robot --exitonerror /autohat/raspberrypi3.robot``
