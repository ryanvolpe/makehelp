.PHONY: all
all:

contrib:
	mkdir -p $@

contrib/bats: | contrib
	if [ -x "$$(which bats)" ]; then \
		touch "$@"; \
	else \
		cd contrib && git clone --depth=1 https://github.com/bats-core/bats-core bats; \
	fi

.PHONY: test
test: PATH:=contrib/bats/bin:$(PATH)
test: contrib/bats
	export PATH=$(PATH) && bats tests/
