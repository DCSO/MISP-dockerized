#
#	Makefile for robot
#
.PHONY:  push-image test test-travis tags show-images pull-all clone-all prepare-docker-compose prepare-makefile

CONTAINER := robot server proxy
DOCKER_COMPOSE_FILE := ../docker-compose.yml
NORMAL_MAKEFILE := ../Makefile
PUBLIC_REPO := dcso/misp

test-travis:
	.travis/travis-cli.sh check

pull-all:
	# pull all images and tags
	$(foreach c, $(CONTAINER), docker pull -a dcso/misp-$(c)-private)

clone-all:
	# clone all repos
	$(foreach c, $(CONTAINER), git clone https://github.com/DCSO/MISP-dockerized-$(c).git ~/$(c);)

prepare-docker-compose:
	#$(foreach c, $(CONTAINER), sed -e -i ',^image,s,dcso/misp-$(c),dcso/misp-$(c)-private,g' $(DOCKER_COMPOSE_FILE);)
	sed -i -e 's,dcso/misp-server.*,dcso/misp-server-private:$(s),g' $(DOCKER_COMPOSE_FILE);
	sed -i -e 's,dcso/misp-robot.*,dcso/misp-robot-private:$(r),g' $(DOCKER_COMPOSE_FILE);
	sed -i -e 's,dcso/misp-proxy.*,dcso/misp-proxy-private:$(p),g' $(DOCKER_COMPOSE_FILE);

prepare-makefile:	
	sed -i 's,dcso/misp-robot,dcso/misp-robot-private:$(r),g' $(NORMAL_MAKEFILE);

show-images:
	$(foreach c, $(CONTAINER), docker images|grep $(c);)

tag:

	$(eval c := server)
	$(eval search_tag := $(s))
	$(eval image_id := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep misp-$(c)-private:$(search_tag)|cut -d : -f 3|head -n 1;))
	$(eval image_tags := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $(image_id)|cut -d : -f 2;))
	$(foreach tag, $(image_tags), \
		docker tag dcso/misp-$(c)-private:$(search_tag) $(PUBLIC_REPO)-$(c):$(tag); \
	)

	$(eval c := proxy)
	$(eval search_tag := $(p))
	$(eval image_id := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep misp-$(c)-private:$(search_tag)|cut -d : -f 3|head -n 1;))
	$(eval image_tags := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $(image_id)|cut -d : -f 2;))
	$(foreach tag, $(image_tags), \
		docker tag dcso/misp-$(c)-private:$(search_tag) $(PUBLIC_REPO)-$(c):$(tag); \
	)

	$(eval c := robot)
	$(eval search_tag := $(r))
	$(eval image_id := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep misp-$(c)-private:$(search_tag)|cut -d : -f 3|head -n 1;))
	$(eval image_tags := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $(image_id)|cut -d : -f 2;))
	$(foreach tag, $(image_tags), \
		docker tag dcso/misp-$(c)-private:$(search_tag) $(PUBLIC_REPO)-$(c):$(tag); \
	)
	@echo "###########################################"
	docker images

test:
	#echo "$(curl -S -k https://localhost/users/login)"|grep Login
	true

push:
	$(foreach c, $(CONTAINER), \
		$(eval image_tags := $(shell docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep 'dcso/misp-$(c):'|cut -d : -f2;)) \
		$(foreach tag, $(image_tags), docker push $(PUBLIC_REPO)-$(c):$(tag);) \
	)
	