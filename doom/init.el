;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

(doom!
 :completion
 (corfu +orderless +icons +dabbrev)
 vertico

 :ui
 doom
 hl-todo
 modeline
 (popup +defaults)
 tabs
 (vc-gutter +pretty)
 workspaces

 :editor
 (evil +everywhere)
 format

 :emacs
 (dired +dirvish +icons)
 (undo +tree)

 :checkers
 (syntax +icons)

 :tools
 lsp
 lookup
 magit
 make
 pdf
 tree-sitter

 :lang
 (cc +lsp +tree-sitter)
 (python +tree-sitter)
 emacs-lisp
 (haskell +lsp)
 (javascript +lsp +tree-sitter)
 (latex +fold +lsp)
 (lua +tree-sitter)
 markdown
 (nix +lsp)
 (org +dragndrop)
 (sh +lsp +fish)
 (web +lsp)
 yaml

 ;; rss is off for now, lisp/modes.el has the steps to bring it back
 ;; :app
 ;; (rss +org)

 :config
 (default +bindings +smartparens))
