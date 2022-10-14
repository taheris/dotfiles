#!/usr/bin/env bash

set -euo pipefail

readonly PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

elisp() {
cat <<EOF
(progn
  (require 'org)
  (setq org-confirm-babel-evaluate nil)
  (org-babel-tangle-file "~/.config/doom/config.org"))
EOF
}

emacs --batch --eval "$(elisp)"
mv -i "${PWD}/*.el" ~/.config/doom
