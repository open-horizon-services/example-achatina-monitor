#
# monitor
#
# This container was originally intended to simply be a debugging utility
# for achatina, but people seem to like it so now it's a fully fledged
# shared service. It is really only useful in the context of achatina
# since it is only able to consume, parse and render MQTT publications
# that have the JSON format that achatina produces.
#
# This container provides a web server on port 5200. This service is also
# exposed on all host interfaces so it can be easily viewed locally or
# remotely.
#
# Written by Glen Darling, Oct 2020.
#

# Include the make file containing all the check-* targets
include ../../checks.mk

# Give this service a name, version number, and pattern name
DOCKER_HUB_ID ?+ ibmosquito
SERVICE_NAME:="monitor"
SERVICE_VERSION:="1.1.0"
PATTERN_NAME:="pattern-monitor"

# These statements automatically configure some environment variables
ARCH:=$(shell ../../helper -a)

# Leave blank for open DockerHub containers
# CONTAINER_CREDS:=-r "registry.wherever.com:myid:mypw"
CONTAINER_CREDS:=

build: check-dockerhubid
	docker build -t $(DOCKER_HUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) -f ./Dockerfile.$(ARCH) .

run: check-dockerhubid
	-docker network create mqtt-net 2>/dev/null || :
	-docker rm -f $(SERVICE_NAME) 2>/dev/null || :
	docker run -d \
           -p 0.0.0.0:5200:5200 \
           --name ${SERVICE_NAME} \
           --network mqtt-net --network-alias ${SERVICE_NAME} \
           $(DOCKER_HUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION)

dev: build check-dockerhubid
	-docker network create mqtt-net 2>/dev/null || :
	-docker rm -f $(SERVICE_NAME) 2>/dev/null || :
	docker run -it -v `pwd`:/outside \
           -p 0.0.0.0:5200:5200 \
           --name ${SERVICE_NAME} \
           --network mqtt-net --network-alias ${SERVICE_NAME} \
           $(DOCKER_HUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) /bin/sh

stop: check-dockerhubid
	@docker rm -f ${SERVICE_NAME} 2>/dev/null || :

clean: check-dockerhubid
	@docker rm -f ${SERVICE_NAME} 2>/dev/null || :
	@docker rmi $(DOCKER_HUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) 2>/dev/null || :

publish-service:
	@ARCH=$(ARCH) \
	    SERVICE_NAME="$(SERVICE_NAME)" \
	    SERVICE_VERSION="$(SERVICE_VERSION)"\
	    SERVICE_CONTAINER="$(DOCKER_HUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION)" \
	    hzn exchange service publish -O $(CONTAINER_CREDS) -P -f service.json --public=true

publish-pattern:
	@ARCH=$(ARCH) \
	    SERVICE_NAME="$(SERVICE_NAME)" \
	    SERVICE_VERSION="$(SERVICE_VERSION)"\
	    PATTERN_NAME="$(PATTERN_NAME)" \
	    hzn exchange pattern publish -f pattern.json

agent-run:
	hzn register --pattern "${HZN_ORG_ID}/$(PATTERN_NAME)"

agent-stop:
	hzn unregister -f

.PHONY: build run dev stop clean publish-service publish-pattern agent-run agent-stop

