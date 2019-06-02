SHELL := /usr/bin/env bash

.PHONY: help deps dump
.DEFAULT_GOAL := help

help: ## Print this message and exit.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%16s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deps: cmd-brew ## Install Brewfile dependencies
	@brew bundle install

dump: cmd-brew ## Update Brewfile dependencies
	@brew bundle dump --force

cmd-%: # Check that a command exists.
	@: $(if $$(command -v ${*} 2>/dev/null),,$(error Please install "${*}" first))
