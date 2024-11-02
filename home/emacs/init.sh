emacs --batch --eval "(progn
  (require 'org)
  (setq org-confirm-babel-evaluate t
        IS-LINUX nil
        IS-MAC t
        IS-WINDOWS nil)
  (org-babel-tangle-file \"./config.org\")
)"
