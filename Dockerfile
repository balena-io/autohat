FROM resin/amd64-alpine:3.4

# Install Python, PIP, RobotFramework, Nodejs and Resin-cli
RUN apk update && apk add nodejs util-linux multipath-tools qemu-system-i386 qemu-system-x86_64 bash udev py-pip && \
	rm -rf /var/cache/apk/* && \
	pip install --upgrade pip && \
	pip install robotframework && \
	npm install --global resin-cli

CMD ['/bin/bash']
