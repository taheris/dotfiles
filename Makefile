SHELL := /usr/bin/env bash

.PHONY: help mac-hostname mac-brew mac-nix mac-flake nixos-boot nixos-home
.DEFAULT_GOAL := help

define get_arg
    $(eval target := $(firstword $(MAKECMDGOALS)))
    $(eval arg := $(target)_arg)
    $(eval $(arg) := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
    $(eval $($(arg))::;@:)
endef

help: ## Print this message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%20s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

mac-hostname: res := $(call get_arg)
mac-hostname: ## Set the macOS hostname (usage: `make set-hostname <name>`)
	@sudo scutil --set HostName $($@_arg)
	@sudo scutil --set LocalHostName $($@_arg)
	@sudo scutil --set ComputerName $($@_arg)

mac-brew: ## Install Homebrew on macOS
	@curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
	@eval "$(/opt/homebrew/bin/brew shellenv)"

mac-nix: ## Install Nix on macOS
	@curl -fsSL https://install.determinate.systems/nix | sh -s -- install

mac-flake: ## Bootstrap nix-darwin on macOS
	@nix run nix-darwin -- switch --flake .

nixos-boot: ## Add a new boot configuration on NixOS
	@nixos-rebuild --flake . boot

nixos-home: ## Bootstrap home-manager on NixOS
	@nix run home-manager/master -- --flake . switch

cmd-%: # Check that a command exists.
	@: $(if $$(command -v ${*} 2>/dev/null),,$(error Please install "${*}" first))
