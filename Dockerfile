FROM alpine:3.4

# Install Python, PIP, RobotFramework, Nodejs and Resin-cli
RUN apk update && apk add nodejs eudev util-linux bash py-pip && \
	rm -rf /var/cache/apk/* && \
	pip install --upgrade pip && \
	pip install robotframework && \
	npm install --global resin-cli 
