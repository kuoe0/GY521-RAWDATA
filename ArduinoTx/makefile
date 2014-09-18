PROJECT_DIR = $(shell pwd)
PROJECT_NAME = $(shell pwd | xargs basename)
SRC_DIR = src
SRC_LINK = src/sketch.ino
MODEL = uno

all: clean build upload

build: $(PROJECT_NAME).ino
	mkdir $(SRC_DIR)
	ln -s $(PROJECT_DIR)/$(PROJECT_NAME).ino $(SRC_LINK)
	ino build -m $(MODEL)

upload: .build/$(MODEL)/firmware.hex
	ino upload -m $(MODEL)

clean:
	ino clean
	if [ -e $(SRC_LINK) ] || [ -h $(SRC_LINK) ]; then rm $(SRC_LINK); fi
	if [ -d $(SRC_DIR) ]; then rmdir $(SRC_DIR); fi
