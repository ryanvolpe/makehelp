.PHONY: all
all:

contrib:
	mkdir -p $@

contrib/bats: | contrib
	cd contrib && git clone https://github.com/bats-core/bats-core bats

.PHONY: test
test: PATH:=contrib/bats/bin:$(PATH)
test: contrib/bats
	bats tests/
