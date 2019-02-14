

upgrade:
	bash ./UPGRADE.sh

update:
	bash ./UPDATE

install:
	bash ./FOR_NEW_INSTALL.sh

new: install

delete:
	make -C current delete
