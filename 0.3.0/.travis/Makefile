#
#	Makefile for robot
#
.PHONY:  push test test-travis tag pull-all pull-latest

CONTAINER := robot server proxy postfix misp-modules
REPOURL := dcso


test-travis:
	./travis-cli.sh check

pull-all:
	# pull all images and tags
	$(foreach c, $(CONTAINER), docker pull -a $(REPOURL)/misp-dockerized-$(c);)

pull-latest:
	$(foreach c, $(CONTAINER), docker pull $(REPOURL)/misp-dockerized-$(c):latest-dev;)

tag:
	./tagging.sh $(REPOURL)/misp-dockerized-server $(server_tag);
	./tagging.sh $(REPOURL)/misp-dockerized-proxy $(proxy_tag);
	./tagging.sh $(REPOURL)/misp-dockerized-robot $(robot_tag);
	./tagging.sh $(REPOURL)/misp-dockerized-postfix $(postfix_tag);
	./tagging.sh $(REPOURL)/misp-dockerized-misp-modules $(modules_tag);
	@echo "###########################################"
	docker images
	@echo "###########################################"


test:
	#echo "$(curl -S -k https://localhost/users/login)"|grep Login
	true

push:
	./push.sh $(REPOURL)/misp-dockerized-server $(server_tag);
	./push.sh $(REPOURL)/misp-dockerized-proxy $(proxy_tag);
	./push.sh $(REPOURL)/misp-dockerized-robot $(robot_tag);
	./push.sh $(REPOURL)/misp-dockerized-postfix $(postfix_tag);
	./push.sh $(REPOURL)/misp-dockerized-misp-modules $(modules_tag);

