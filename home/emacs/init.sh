emacs --batch --eval "(progn
  (require 'org)
  (setq org-confirm-babel-evaluate t
        IS-LINUX t
        IS-MAC nil
        IS-WINDOWS nil)
  (org-babel-tangle-file \"./config.org\")
)"
