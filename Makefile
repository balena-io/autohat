DOCKER_IMAGE = autohat

build-docker-image: Dockerfile
	@echo '[Info] Building docker image "$(DOCKER_IMAGE)"...'
	@docker build -t $(DOCKER_IMAGE) .

test: build-docker-image
	@echo '[Info] Starting tests inside container...'
	@docker run -it --rm --name ${DOCKER_IMAGE} \
		-v /home/horia/sandbox/autohat/:/autohat \
		-v /dev/:/dev2 --privileged \
		--env-file ./env.list \
		$(DOCKER_IMAGE) \
		robot --exitonerror /autohat/qemu.robot

enter:
ifeq ("$(shell docker inspect -f '{{.State.Running}}' ${DOCKER_IMAGE} 2>/dev/null)","true")
	@echo '[Info] You are inside container "${DOCKER_IMAGE}"'
	@docker exec -it ${DOCKER_IMAGE} bash
else
	@echo '[Error] Container "${DOCKER_IMAGE}" is not running!'
endif

clean:
	@echo '[Info] Removing docker image "$(DOCKER_IMAGE)"...'
	@docker rmi $(DOCKER_IMAGE)

.Phony: build-docker-image test enter clean

.DEFAULT_GOAL = test
