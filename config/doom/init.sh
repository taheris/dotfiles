#!/usr/bin/env bash

set -euo pipefail

elisp() {
cat <<EOF
(progn
  (require 'org)
  (setq org-confirm-babel-evaluate nil)
  (org-babel-tangle-file "~/.config/doom/config.org"))
EOF
}

emacs --batch --eval "$(elisp)"
