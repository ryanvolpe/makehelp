#: Test management for *[makehelp]*.

.$(verbose)SILENT:

DEP_CACHE ?= .depcache
DEP_BUILDROOT ?= .build-deps

INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 555
INSTALL_DATA ?= $(INSTALL) -m 644

INFO  = \033[32mINFO\033[0m
WARN  = \033[33mWARN\033[0m
ERROR = \033[1m\033[31mERROR\033[0m

srcdir ?= .
SRCS := $(srcdir)/makehelp.sh
TESTS := $(srcdir)/tests/

# dependency aliases
kcov := $(DEP_CACHE)/kcov
bats := $(DEP_CACHE)/bats

.PHONY: all
all:
	@echo "$(INFO) No target specified; run \033[1mmake help\033[0m for a list of targets."

.PHONY: clean
#: Removes build cruft.
clean:
	rm -rf $(DEP_BUILDROOT) $(DEP_CACHE)

.PHONY: test
#: Runs automated tests.
test: $(bats)
	"$(bats)" $(TESTS)

#: Generates test coverage using _[kcov]_.
coverage: $(kcov) $(bats) $(SRCS) $(TESTS)
	"$(kcov)" --include-path=. "$@" "$(bats)" $(TESTS)

#: Display this help message and exit.
help:
	makehelp.sh "$(lastword $(MAKEFILE_LIST))"

## DEPENDENCY MANAGEMENT

.PHONY: localdeps
#: Force-populate the dependency cache, preferring any locally-installed
#: versions over source builds.
localdeps:
	$(INSTALL) -d "$(DEP_CACHE)"
	ln -s "$$(which kcov)" "$(DEP_CACHE)/" 2>/dev/null || true
	ln -s "$$(which bats)" "$(DEP_CACHE)/" 2>/dev/null || true
	$(MAKE) "$(kcov)" "$(bats)"

$(kcov):
	$(MAKE) "$(DEP_BUILDROOT)/kcov-build"
	@echo "$(INFO) Installing kcov to package cache."
	$(INSTALL) -d "$(@D)"
	$(INSTALL_PROGRAM) "$(DEP_BUILDROOT)/kcov-build/src/kcov" "$@"
	rm -rf "$(DEP_BUILDROOT)"

$(bats):
	$(MAKE) $(DEP_BUILDROOT)/bats-build
	@echo "$(INFO) Installing bats to package cache."
	$(INSTALL) -d "$(@D)"
	$(INSTALL_PROGRAM) "$(DEP_BUILDROOT)/bats-build/libexec/bats" "$@"
	find "$(DEP_BUILDROOT)/bats-build/libexec" -name 'bats-*' -exec $(INSTALL_PROGRAM) {} "$(@D)" \;
	rm -rf "$(DEP_BUILDROOT)"

.PRECIOUS: $(DEP_BUILDROOT)/%-version
$(DEP_BUILDROOT)/%-version:
	# not efficient, but run X times and prevents Xmb of download traffic
	@echo "$(INFO) Determine latest release of $*"
	$(INSTALL) -d $(DEP_BUILDROOT)
	if [ -n "$($*_use_head)" ]; then \
		echo "$(WARN) Overriden to use HEAD revision of $*"; \
		echo "HEAD" > "$@"; \
	elif [ -n "$($*_version)" ]; then \
		echo "$(INFO) $* version set to $($*_version) explicitly"; \
		echo "$($*_version)" > "$@"; \
	elif [ -n "$(GITHUB_REPO)" ]; then \
		version=$$(\git ls-remote --tags "https://github.com/$(GITHUB_REPO)" \
			| awk '{print $$2}' \
			| grep -v '{}' \
			| awk -F/ '{print $$3}' \
			| awk -Fv '{print $$2 " " $$0}' \
			| sort -n \
			| tail -1 \
			| awk '{print $$2}') \
		&& echo $$version > "$@"; \
		echo "$(INFO) Using version $$version"; \
	else \
		exit 1; \
	fi

$(DEP_BUILDROOT)/kcov-%: GITHUB_REPO = SimonKagstrom/kcov
$(DEP_BUILDROOT)/bats-%: GITHUB_REPO = bats-core/bats-core
$(DEP_BUILDROOT)/bats-%: BATS_ROOT = $(DEP_BUILDROOT)/bats-src
$(DEP_BUILDROOT)/bats-%: BATS_VERSION = $(shell cat $(DEP_BUILDROOT)/bats-version)
$(DEP_BUILDROOT)/kcov-%: KCOV_VERSION = $(shell cat $(DEP_BUILDROOT)/kcov-version)

$(DEP_BUILDROOT)/%-src: DEP_VERSION = $(shell cat $(DEP_BUILDROOT)/$*-version)
$(DEP_BUILDROOT)/%-src: $(DEP_BUILDROOT)/%-version
	@printf "$(INFO) Cloning dependency: %s@%s\n" "$*" "$(DEP_VERSION)"
	$(INSTALL) -d "$(@D)"
	if [ "$(DEP_VERSION)" = "HEAD" ]; then \
		GIT_BRANCH=; \
	else \
		GIT_BRANCH="--branch $(DEP_VERSION)"; \
	fi \
		&& \git clone --depth=1 $$GIT_BRANCH "https://github.com/$(GITHUB_REPO)" "$@"

$(DEP_BUILDROOT)/bats-test: $(DEP_BUILDROOT)/bats-src
	@echo "$(INFO) Testing bats@$(BATS_VERSION)"
	"$(BATS_ROOT)/libexec/bats" "$(BATS_ROOT)/test" \
		|| (echo "$(ERROR) Tests failed!" && exit 1)

$(DEP_BUILDROOT)/bats-build: $(DEP_BUILDROOT)/bats-test
	@echo "$(INFO) Finalizing build of bats@$(BATS_VERSION)"
	# NOTE: this line needs to change if $@ and $< aren't the same directory
	touch "$<"
	ln -s "bats-src" "$@"

$(DEP_BUILDROOT)/kcov-test: $(DEP_BUILDROOT)/kcov-src
	@echo "$(INFO) Testing kcov@$(KCOV_VERSION)"
	# hijack kcov's travis infrastructure for running tests...
	if [ ! -n "$(TRAVIS_OS_NAME)" ]; then \
		if [ "$$(uname -s)" = "Darwin" ]; then \
			KCOV_MAKE_ARGS="TRAVIS_OS_NAME=osx CC=clang"; \
		else \
			KCOV_MAKE_ARGS="TRAVIS_OS_NAME=linux CC=gcc"; \
		fi \
	fi \
	&& cd "$<" && $(MAKE) -f "travis/Makefile" $$KCOV_MAKE_ARGS prepare_environment run-tests \
		|| (echo "$(ERROR) Tests failed!" && exit 1)

$(DEP_BUILDROOT)/kcov-build: $(DEP_BUILDROOT)/kcov-test
	@echo "$(INFO) Finalizing build of kcov@$(KCOV_VERSION)..."
	touch "$<"		# kcov-test succeeded, make sure it doesn't run again
	ln -sf "$(realpath $(DEP_BUILDROOT)/kcov-src)/build" "$@"
