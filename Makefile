
help:
	@echo -e " \
		make help	| Shows this help text. \n \
		make new 	| The same as make install. \n \
		make install 	| Let you choose a new version. \n \
		make update 	| Update container but not upgrade to a new version. \n \
		make upgrade 	| Upgrade to a new version. \n \
		make delete		| Removes the MISP-dockerized volumes, container and network."

upgrade:
	bash ./UPGRADE.sh

update:
	bash ./UPDATE

install:
	bash ./FOR_NEW_INSTALL.sh
	make -C current install

new: install

delete:
	make -C current delete

support:
	bash .scripts/support.sh

change-ssl:
	-make -C current change-ssl

change-smime:
	-make -C current change-smime

change-pgp:
	-make -C current change-pgp
