setup:
	shards install

run:
	crystal run src/nes.cr

build:
	crystal build src/nes.cr

lint:
	./bin/ameba
