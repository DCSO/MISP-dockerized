#
#	Makefile for robot
#
.PHONY:  push test test-travis tag pull-all pull-latest

CONTAINER := robot server proxy postfix
REPOURL := dcso


test-travis:
	./travis-cli.sh check

pull-all:
	# pull all images and tags
	$(foreach c, $(CONTAINER), docker pull -a $(REPOURL)-$(c);)

pull-latest:
	$(foreach c, $(CONTAINER), docker pull $(REPOURL)-$(c):latest-dev;)

tag:
	./tagging.sh $(REPOURL)-server $(server_tag);
	./tagging.sh $(REPOURL)-proxy $(proxy_tag);
	./tagging.sh $(REPOURL)-robot $(robot_tag);
	./tagging.sh $(REPOURL)-postfix $(postfix_tag);
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

