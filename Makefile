
.PHONY: install
install:
	rsync -avrz content/* djs@dark.recoil.org:/data/www/dave.recoil.org/
