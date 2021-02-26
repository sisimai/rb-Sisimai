# rb-sisimai/Makefile
#  __  __       _         __ _ _      
# |  \/  | __ _| | _____ / _(_) | ___ 
# | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
# | |  | | (_| |   <  __/  _| | |  __/
# |_|  |_|\__,_|_|\_\___|_| |_|_|\___|
# -----------------------------------------------------------------------------
SHELL := /bin/sh
TIME  := $(shell date '+%s')
NAME  := sisimai
RUBY  ?= ruby
JRUBY ?= /usr/local/jr
RAKE  ?= rake
MKDIR := mkdir -p
CP    := cp
RM    := rm -f

DEPENDENCIES  = bundle rake minitest
.DEFAULT_GOAL = git-status
REPOS_TARGETS = git-status git-push git-commit-amend git-tag-list git-diff \
				git-reset-soft git-rm-cached git-branch
DEVEL_TARGETS = private-sample
BENCH_TARGETS = profile speed-test loc


# -----------------------------------------------------------------------------
.PHONY: clean

depend:
	gem install $(DEPENDENCIES)
	if [ test -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" $(JRUBY)/bin/gem install $(DEPENDENCIES); \
	fi

install-from-rubygems:
	gem install $(NAME)
	if [ test -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" $(JRUBY)/bin/gem install $(NAME); \
	fi

install-from-local:
	$(RAKE) install
	if [ test -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" $(JRUBY)/bin/rake install; \
	fi

build:
	$(RAKE) $@ 
	if [ -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" $(JRUBY)/bin/rake $@; \
	fi

release:
	$(RAKE) release
	if [ -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" $(JRUBY)/bin/rake release; \
	fi

test: user-test author-test
user-test:
	rake publictest

author-test:
	rake privatetest

check:
	find lib -type f -exec grep --color -E ' $$' {} /dev/null \;
	find lib -type f -exec grep --color -E '[;][ ]*$$' {} /dev/null \;

jruby-test:
	if [ -d "$(JRUBY)" ]; then \
		PATH="$(JRUBY)/bin:$$PATH" LS_HEAP_SIZE='1024m' $(JRUBY)/bin/rake publictest; \
	fi

patrol:
	rubocop -fp --display-cop-names --display-style-guide --no-color lib

$(REPOS_TARGETS):
	$(MAKE) -f Repository.mk $@

$(DEVEL_TARGETS):
	$(MAKE) -f Developers.mk $@

$(BENCH_TARGETS):
	$(MAKE) -f Benchmarks.mk $@

diff push branch:
	@$(MAKE) git-$@
fix-commit-message: git-commit-amend
cancel-the-latest-commit: git-reset-soft
remove-added-file: git-rm-cached

clean:
	$(MAKE) -f Repository.mk clean
	$(MAKE) -f Benchmarks.mk clean

