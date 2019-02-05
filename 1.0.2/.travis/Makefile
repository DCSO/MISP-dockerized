#
#	Makefile for robot
#
.PHONY:  push test test-travis tag pull-all pull-latest

CONTAINER := robot server proxy misp-modules
REPOURL := dcso

pull-latest:
	docker pull $(REPOURL)/misp-dockerized-proxy:latest-dev;
	docker pull $(REPOURL)/misp-dockerized-robot:latest-dev;
	docker pull $(REPOURL)/misp-dockerized-misp-modules:latest-dev;

tag:
	bash ./tagging.sh $(REPOURL)/misp-dockerized-server $(server_tag);
	bash ./tagging.sh $(REPOURL)/misp-dockerized-proxy $(proxy_tag);
	bash ./tagging.sh $(REPOURL)/misp-dockerized-robot $(robot_tag);
	bash ./tagging.sh $(REPOURL)/misp-dockerized-misp-modules $(modules_tag);
	@echo "###########################################"
	docker images
	@echo "###########################################"


test:
	@echo "################		Start Tests		###########################"
	-docker exec misp-robot bash -c "/srv/scripts/test.sh"
	@if [ ! -d reports ]; then mkdir reports; fi
	@docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. reports/

push:
	bash ./push.sh $(REPOURL)/misp-dockerized-server $(server_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-proxy $(proxy_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-robot $(robot_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-misp-modules $(modules_tag);
