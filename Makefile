CWD := $(shell pwd)
NAME := $(shell jq -r .name META6.json)
VERSION := $(shell jq -r .version META6.json)
ARCHIVENAME := $(subst ::,-,$(NAME))

check:
	git diff-index --check HEAD

tag:
	git tag $(VERSION)
	git push origin --tags

dist:
	git archive --prefix=$(ARCHIVENAME)-$(VERSION)/ \
		-o ../$(ARCHIVENAME)-$(VERSION).tar.gz $(VERSION)

test-alpine:
	docker run --rm -t  \
	  -e ALL_TESTING=1 \
	  -v $(CWD):/test \
          --entrypoint="/bin/sh" \
	  jjmerelo/raku-test \
	  -c "apk add --update --no-cache sqlite-libs && zef install --/test --deps-only --test-depends . && zef -v test ."

test-nightly:
	docker run --rm -t \
	  -e ALL_TESTING=1 \
	  -v $(CWD):/tmp/test -w /tmp/test \
	  tonyodell/rakudo-nightly:latest \
	  bash -c 'zef install --/test --deps-only --test-depends . && zef -v test .'

test-debian:
	docker run --rm -t \
	  -e ALL_TESTING=1 \
	  -v $(CWD):/test -w /test \
          --entrypoint="/bin/sh" \
	  jjmerelo/rakudo-nostar \
	  -c "zef install --/test --deps-only --test-depends . && zef -v test ."

test: test-alpine test-debian test-nightly
