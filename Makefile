SHELL := /usr/bin/env bash

STOW_HOME := tmux
STOW_CONFIG := alacritty karabiner

.PHONY: help stow unstow deps dump
.DEFAULT_GOAL := help

help: ## Print this message and exit.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%16s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

stow: cmd-stow ## Symlink dotfiles
	@for dir in $(STOW_CONFIG); do mkdir -p ~/.config/$$dir; done
	@for dir in $(STOW_HOME);   do stow $$dir --target=$(HOME); done
	@for dir in $(STOW_CONFIG); do stow $$dir --target=$(HOME)/.config/$$dir; done

unstow: cmd-stow ## Remove symlinks
	@for dir in $(STOW_HOME);   do stow --delete $$dir --target=$(HOME); done
	@for dir in $(STOW_CONFIG); do stow --delete $$dir --target=$(HOME)/.config/$$dir; done

deps: cmd-brew ## Install Brewfile dependencies
	@brew bundle install

dump: cmd-brew ## Update Brewfile dependencies
	@brew bundle dump --force

cmd-%: # Check that a command exists.
	@: $(if $$(command -v ${*} 2>/dev/null),,$(error Please install "${*}" first))
