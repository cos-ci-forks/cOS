BACKEND?=docker
CONCURRENCY?=1
PACKAGES?=

export LUET?=/usr/bin/luet
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/build
COMPRESSION?=zstd
CLEAN?=false
export TREE?=$(ROOT_DIR)/packages

BUILD_ARGS?= --live-output --pull --no-spinner --only-target-package
SUDO?=
VALIDATE_OPTIONS?=-s
ARCH?=amd64
REPO_CACHE?=raccos/$(ARCH)
FINAL_REPO?=raccos/releases-$(ARCH)
export REPO_CACHE
ifneq ($(strip $(REPO_CACHE)),)
	BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

all: deps build

deps:
	@echo "Installing luet"
	go get -u github.com/mudler/luet

clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) $(PACKAGES) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) --all --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) $(PACKAGES) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) --all --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

rebuild-full:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) --full --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

build-full: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values $(ROOT_DIR)/values/$(ARCH).yaml --tree=$(TREE) --full --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

create-repo:
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(DESTINATION) \
    --packages $(DESTINATION) \
    --name "cOS" \
    --descr "cOS $(ARCH)" \
    --urls "" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar \
    --meta-compression $(COMPRESSION) \
    --type http

publish-repo:
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(FINAL_REPO) \
    --packages $(DESTINATION) \
    --name "cOS" \
    --descr "cOS $(ARCH)" \
    --urls "" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar \
    --meta-compression $(COMPRESSION) \
    --push-images \
    --type docker

serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(ROOT_DIR)/build &

auto-bump:
	TREE_DIR=$(ROOT_DIR) $(LUET) autobump-github

autobump: auto-bump

validate:
	$(LUET) tree validate --tree $(TREE) $(VALIDATE_OPTIONS)

local-iso: create-repo
	$(SUDO) touch $(ROOT_DIR)/build/conf.yaml || true
	$(SUDO) yq w -i $(ROOT_DIR)/build/conf.yaml 'repositories[0].name' 'local'
	$(SUDO) yq w -i $(ROOT_DIR)/build/conf.yaml 'repositories[0].type' 'disk'
	$(SUDO) yq w -i $(ROOT_DIR)/build/conf.yaml 'repositories[0].enable' true
	$(SUDO) yq w -i $(ROOT_DIR)/build/conf.yaml 'repositories[0].urls[0]' $(DESTINATION)
	$(SUDO) luet geniso-isospec $(ROOT_DIR)/iso/cOS-local.yaml
