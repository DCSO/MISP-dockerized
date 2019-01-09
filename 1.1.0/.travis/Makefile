#
#	Makefile for robot
#
.PHONY:  push test test-travis tag pull-all pull-latest

CONTAINER := robot server proxy misp-modules
REPOURL := dcso


test-travis:
	./travis-cli.sh check

pull-all:
	# pull all images and tags
	$(foreach c, $(CONTAINER), docker pull -a $(REPOURL)/misp-dockerized-$(c);)

pull-latest:
	$(foreach c, $(CONTAINER), docker pull $(REPOURL)/misp-dockerized-$(c):latest-dev;)

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
	-docker exec misp-robot bash /srv/scripts/test.sh
	@if [ ! -d reports ]; then mkdir reports; fi
	@docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. reports/

push:
	bash ./push.sh $(REPOURL)/misp-dockerized-server $(server_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-proxy $(proxy_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-robot $(robot_tag);
	bash ./push.sh $(REPOURL)/misp-dockerized-misp-modules $(modules_tag);
