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
	@echo "################		Start Tests		###########################"
	-docker exec misp-robot bash -c "/srv/scripts/test.sh"
	@if [ ! -d reports ]; then mkdir reports; fi
	@docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. reports/

push:
	@bash 30_push.sh $(REPO) $(USER) $(PW)

script:
	@bash 02_script.sh $(REPO) $(USER) $(PW) $(test) $(VERSION)