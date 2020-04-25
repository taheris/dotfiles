;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Shaun Taheri"
      user-mail-address "git@taheris.net")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "Monaco" :size 16))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-dracula)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.


; global settings
(setq confirm-kill-emacs nil
      doom-localleader-key ","
      make-pointer-invisible t
      mouse-drag-copy-region t)

; key-bindings
(map! :leader
      :desc "Project search" "/" #'+ivy/project-search
      :desc "Deer"           "d" #'deer

      (:prefix ("t" . "toggle")
        :desc "Golden ratio" "g" #'golden-ratio-mode))

; company
(after! company
  (setq company-box-doc-enable nil
        company-selection-wrap-around t)

  (define-key! company-active-map
               "TAB"    #'company-complete-selection
               [tab]    #'company-complete-selection
               "RET"    nil
               [return] nil))

; lsp
(after! lsp
  (setq lsp-enable-file-watchers nil
        +lsp-defer-shutdown 60)

  (set-formatter! 'lsp-formatter #'lsp-format-buffer
                  :modes '(lsp-mode)))

(after! lsp-ui
  (setq lsp-ui-doc-enable nil
        lsp-signature-render-documentation nil))

; rust
(after! rustic
  (setq rustic-lsp-server 'rust-analyzer
        rustic-format-trigger 'on-save
        rustic-test-arguments "--all-features"
        lsp-rust-analyzer-cargo-watch-command "clippy")

  (map! :localleader
        :map rustic-mode-map

        :desc "Execute code action" "a" #'lsp-execute-code-action
        :desc "Toggle inlay hints"  "h" #'lsp-rust-analyzer-inlay-hints-mode
        :desc "Join lines"          "j" #'lsp-rust-analyzer-join-lines
        :desc "Expand macro"        "x" #'lsp-rust-analyzer-expand-macro

        (:prefix ("t" . "cargo test")
          :desc "run tests"    "t" #'rustic-cargo-test
          :desc "all features" "a" #'rustic-cargo-test-rerun
          :desc "test current" "c" #'rustic-cargo-current-test)

        (:prefix ("g" . "goto")
          :desc "Definition"      "d" #'lsp-find-definition
          :desc "Implementation"  "i" #'lsp-find-implementation
          :desc "Reference"       "r" #'lsp-find-references
          :desc "Type definition" "t" #'lsp-find-type-definition)))

; golden-ratio
(use-package! golden-ratio
  :after-call pre-command-hook
  :config
    (setq golden-ratio-auto-scale t)
    (golden-ratio-mode 1)
    (add-hook 'doom-switch-window-hook #'golden-ratio))
