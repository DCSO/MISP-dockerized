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

# https://stackoverflow.com/questions/13068152/grep-exit-codes-in-makefile#13069387
test:
	@echo "################		Start Tests		###########################"
	@if [ ! -d reports ]; then mkdir reports; fi ;\
	docker exec misp-robot bash -c "sleep 10 && /srv/scripts/test.sh" 2> reports/error.txt \
	retVal=$$? ;\
	docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. reports/ ;\
	if $$retval; then echo ""; \
		echo "[ERROR] Test was not successful. Output Logs from Container and exit."; echo ""; \
		echo "error output:"; cat reports/error.txt; echo ""; \
		echo "misp-proxy:"; docker logs misp-proxy --tail 20; echo ""; \
		echo "misp-server:"; docker logs misp-server --tail 20; echo "";  \
		echo "misp-modules:" ; docker logs misp-modules --tail 20; echo ""; \
		echo "[ERROR] Test was not successful."; echo ""; \
		exit 1 ;\
	else "[Info] Test was successful" && echo ""  && exit 0; fi

tag:
	@bash 20_tag_2_registry.sh $(REPOURL) $(USER) $(PW)

push:
	@bash 30_push_2_registry.sh $(REPOURL) $(USER) $(PW)

script:
	@bash 02_script.sh $(REPOURL) $(USER) $(PW) $(TEST) $(VERSION)