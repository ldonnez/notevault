IMAGE_NAME := nv-sh
CONTAINER_NAME := $(IMAGE_NAME)
VOLUME_MOUNT := -v $(shell pwd):/opt

NV_INSTALL_DIR := ~/.local/bin

# Ensures it does not interferes with local files/directories named test or build etc...
.PHONY: dev install uninstall

dev:
	chmod +x $(CURDIR)/nv.sh
	@printf "Symlinking $(CURDIR)/nv.sh -> $(NV_INSTALL_DIR)/nv...\n"
	mkdir -p $(NV_INSTALL_DIR)
	ln -sf $(CURDIR)/nv.sh $(NV_INSTALL_DIR)/nv

	@printf "Installation complete!\n"
	@printf "Ensure $(NV_INSTALL_DIR) is in your shell's PATH.\n"

install:
	@printf "Installing nv bash script to $(NV_INSTALL_DIR)...\n"
	mkdir -p $(NV_INSTALL_DIR)
	install -m 0700 nv.sh $(NV_INSTALL_DIR)/nv

	@printf "Installation complete!\n"
	@printf "Ensure $(NV_INSTALL_DIR) is in your shell's PATH.\n"
	
uninstall:
	@printf "Deleting $(CACHE_BUILDER_INSTALL_DIR)\n"
	@rm -rf $(CACHE_BUILDER_INSTALL_DIR)

	@printf "Deleting $(NV_INSTALL_DIR)/nv\n"
	@rm -rf $(NV_INSTALL_DIR)/nv

	@printf "Uninstall complete!\n"

docker/build-image:
	@docker build -t $(IMAGE_NAME) .

docker/shell:
	@docker run --rm -it --name $(CONTAINER_NAME) $(VOLUME_MOUNT) $(IMAGE_NAME) /bin/bash; \

test:
	@docker run --rm $(VOLUME_MOUNT) $(IMAGE_NAME) bats test/$(file)
