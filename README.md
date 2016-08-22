# Autohat - Automated Hardware Testing
### Technology preview

This projects hopes to make it easy to do automated testing of OS images. This test framework is based on [robotframework](http://robotframework.org). The included resources should make it easy to write tests in Gherkin.

The resources directory contains Robot Keyword helpers for ``resincli`` and hardware specific .robot files. This could be extended to add helpers for other cli tools and hardware. We have included a Dockerfile to setup the environment required to run the example.

### Instructions for running the example:

* Clone this repo and change your directory to it.
* Build the autohat container by running the following command:

  ``docker build -t autohat .``
  
* Build a resin-qemux86-64 image from [https://github.com/resin-os/resin-qemu/](https://github.com/resin-os/resin-qemu/)

* Alternatively you can also download a uninitialized qemux86-64 image from resin by executing:

  ``resin os download qemux86-64 -o resin.img``
  
* Create a `env.list` with all the environment variables needed to run the tests - Please check `env.list.example` for a sample environment file.
  
* Load the KVM module

* Execute the following to run a example test against the qemux86-64 image you just downloaded.

    ``docker run -it --rm -v <path_to_repo>:/autohat -v /dev/:/dev2 --privileged --env-file ./env.list autohat robot --exitonerror /autohat/qemux86-64.robot``
    
