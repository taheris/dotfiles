SHELL := /usr/bin/env bash

STOW_HOME := $(patsubst home/%/, %, $(dir $(wildcard home/*/)))
STOW_CONFIG := $(patsubst config/%/, %, $(dir $(wildcard config/*/)))

.PHONY: help stow unstow brew deps
.DEFAULT_GOAL := help

help: ## Print this message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%10s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

stow: cmd-stow ## Symlink dotfiles
	@for dir in $(STOW_HOME);   do stow --dir home $$dir --target=$(HOME); done
	@for dir in $(STOW_CONFIG); do mkdir -p ~/.config/$$dir; done
	@for dir in $(STOW_CONFIG); do stow --dir config $$dir --target=$(HOME)/.config/$$dir; done

unstow: cmd-stow ## Remove symlinks
	@for dir in $(STOW_HOME);   do stow --delete --dir home $$dir --target=$(HOME); done
	@for dir in $(STOW_CONFIG); do stow --delete --dir config $$dir --target=$(HOME)/.config/$$dir; done
	@for dir in $(STOW_CONFIG); do rmdir ~/.config/$$dir 2>/dev/null; done

brew: cmd-brew ## Install Brewfile dependencies
	@brew bundle install

deps: cmd-brew ## Update Brewfile dependencies
	@brew bundle dump --force

cmd-%: # Check that a command exists.
	@: $(if $$(command -v ${*} 2>/dev/null),,$(error Please install "${*}" first))
