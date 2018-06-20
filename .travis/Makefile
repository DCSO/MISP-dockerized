#
#	Makefile for robot
#
.PHONY:  push-image test test-travis tags show-images pull-all clone-all prepare-docker-compose prepare-makefile

CONTAINER := robot server proxy postfix
REPOURL := dcso/misp-dockerized
DOCKER_COMPOSE_FILE := ../docker-compose.yml
NORMAL_MAKEFILE := ../Makefile
ENV_FILE := ../config/.env


test-travis:
	.travis/travis-cli.sh check

pull-all:
	# pull all images and tags
	$(foreach c, $(CONTAINER), docker pull -a $(REPOURL)-$(c);)

pull-latest:
	$(foreach c, $(CONTAINER), docker pull $(REPOURL)-$(c):latest;)

prepare-docker-compose:
	sed -i 's,^.*_CONTAINER_TAG=.*-.*$$,&-dev,g' $(ENV_FILE);

prepare-makefile:	
	sed -i 's,dcso/misp-robot,dcso/MISP-dockerized-robot:$(r),g' $(NORMAL_MAKEFILE);
	sed -i 's,build_config.sh,build_config.sh --automated-build,g' $(NORMAL_MAKEFILE);

tag:
	.travis/tagging.sh $(REPOURL)-server $(server)
	.travis/tagging.sh $(REPOURL)-proxy $(proxy)
	.travis/tagging.sh $(REPOURL)-robot $(robot)
	.travis/tagging.sh $(REPOURL)-postfix $(postfix)

test:
	#echo "$(curl -S -k https://localhost/users/login)"|grep Login
	true

push:
	.travis/push.sh $(REPOURL)-server $(server)
	.travis/push.sh $(REPOURL)-proxy $(proxy)
	.travis/push.sh $(REPOURL)-robot $(robot)
	.travis/push.sh $(REPOURL)-postfix $(postfix)
