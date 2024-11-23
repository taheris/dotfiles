SHELL := /usr/bin/env bash

.PHONY: help set-hostname install-brew install-nix install-flake
.DEFAULT_GOAL := help

define get_arg
    $(eval target := $(firstword $(MAKECMDGOALS)))
    $(eval arg := $(target)_arg)
    $(eval $(arg) := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
    $(eval $($(arg))::;@:)
endef

help: ## Print this message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%20s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

set-hostname: res := $(call get_arg)
set-hostname: ## Set the macOS hostname (usage: `make set-hostname <name>`)
	@sudo scutil --set HostName $($@_arg)
	@sudo scutil --set LocalHostName $($@_arg)
	@sudo scutil --set ComputerName $($@_arg)

install-brew: ## Install Homebrew
	@curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
	@eval "$(/opt/homebrew/bin/brew shellenv)"

install-nix: ## Install Nix
	@curl -fsSL https://install.determinate.systems/nix | sh -s -- install

install-flake: ## Install nix-darwin with flake
	@nix run nix-darwin -- switch --flake .

cmd-%: # Check that a command exists.
	@: $(if $$(command -v ${*} 2>/dev/null),,$(error Please install "${*}" first))
