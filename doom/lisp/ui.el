;;; lisp/ui.el -*- lexical-binding: t; -*-

;;; fonts and theme

(setq doom-font (font-spec :family "Monaspace Neon NF" :size 16)
      doom-symbol-font (font-spec :family "Unifont"))

;; the +icons flags draw nerd font glyphs; this font already has them
(setq nerd-icons-font-family "Monaspace Neon NF")

(setq doom-theme 'base16-bubblegum)

;; emacs never picks an italic font, so italic faces draw upright and bold italic
;; draws bold. it works on fonts, not faces, so it covers every theme and package
(add-to-list 'face-ignored-fonts "-\\(?:italic\\|oblique\\)-")
;; faces drawn before this line keep their font until the cache goes, as on a reload
(clear-face-cache t)

;;; modeline

(setq nyan-animate-nyancat t
      nyan-animation-frame-interval 0.5)
(unless (bound-and-true-p nyan-mode)
  (nyan-mode 1))

;; main with the workspace name where the tab-bar name would go
(after! doom-modeline
  (setq doom-modeline-persp-name t)
  (doom-modeline-def-modeline 'main
    '(eldoc bar window-state persp-name window-number modals matches follow
      buffer-info remote-host buffer-position word-count selection-info)
    '(compilation misc-info project-name github debug repl lsp minor-modes
      input-method indent-info buffer-encoding major-mode process vcs check time)))
