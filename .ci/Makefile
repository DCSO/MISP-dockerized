#
#	Makefile
#
.PHONY: help build tags push notify-hub-docker-com push test test-travis tag pull-all pull-latest

help:
	@echo -e "Please use a command: \n \
		make pull-latest $(REPOURL) \n \
		make test \n \
		make push $(REPO) $(USER) $(PW) \n \
	"

CONTAINER := robot server proxy misp-modules
REPOURL := dcso

pull-latest:
	docker pull $(REPOURL)/misp-dockerized-proxy:latest-dev;
	docker pull $(REPOURL)/misp-dockerized-robot:latest-dev;
	docker pull $(REPOURL)/misp-dockerized-misp-modules:latest-dev;

test:
	@bash 03_test.sh

tag:
	@bash 20_tag_2_registry.sh $(REPOURL) $(USER) $(PW)

push:
	@bash 30_push_2_registry.sh $(REPOURL) $(USER) $(PW)

script:
	@bash 02_script.sh $(REPOURL) $(USER) $(PW) $(TEST) $(VERSION)