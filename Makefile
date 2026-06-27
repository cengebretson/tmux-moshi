.PHONY: help test lint release

SHELL_FILES = scripts/moshi-status scripts/moshi-toggle scripts/moshi-seed-pairing scripts/moshi-doctor tests/check.sh tmux-moshi.tmux

help:
	@echo "make test    - run the integration suite (tests/check.sh)"
	@echo "make lint    - shellcheck the scripts and plugin entry"
	@echo "make release - how to cut a release"

test:
	tests/check.sh

lint:
	shellcheck $(SHELL_FILES)

release:
	@echo "Cut a release with: git release <x.y.z|major|minor|patch> --push"
