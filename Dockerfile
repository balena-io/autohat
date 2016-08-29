FROM resin/amd64-alpine:3.4

# Install Python, PIP, RobotFramework, Nodejs and Resin-cli
RUN apk update && apk add nodejs util-linux multipath-tools git openssh-client qemu-system-i386 qemu-system-x86_64 bash udev py-pip && \
	rm -rf /var/cache/apk/* && \
	pip install --upgrade pip && \
	pip install robotframework requests robotframework-requests && \
	npm install --global resin-cli@^4.4.0

ADD fixtures/ssh_config /root/.ssh/config

RUN chmod 400 /root/.ssh/*

CMD ['/bin/bash']
