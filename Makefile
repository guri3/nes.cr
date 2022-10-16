.PHONY: setup
setup:
	shards install

.PHONY: run
run:
	crystal run src/nes.cr

.PHONY: build
build:
	crystal build src/nes.cr

.PHONY: spec
spec:
	crystal spec

.PHONY: lint
lint:
	./bin/ameba
