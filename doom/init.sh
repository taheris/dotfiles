#!/usr/bin/env bash

set -euo pipefail

emacs --batch --eval "(progn \
  (require 'org) \
  (setq org-confirm-babel-evaluate nil) \
  (org-babel-tangle-file \"~/.config/doom/config.org\"))"

mv *.el ~/.config/doom
