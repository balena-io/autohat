# autohat - Automated Hardware Testing
> used by balenaCloud E2E tests

## Troubleshooting
> Ctrl-A-X to exit QEMU monitor

    docker exec -ti {{id-or-name-of-running-autohat-container}} bash

    minicom -D unix\#/tmp/console.sock
