;;; lisp/pyret.el -*- lexical-binding: t; -*-

;; pyret's own emacs mode for .arr files. lisp/vendor/pyret.el is an unmodified copy of
;; tools/emacs/pyret.el from github.com/brownplt/pyret-lang, branch horizon (apache 2.0,
;; see lisp/vendor/pyret.LICENSE)

(autoload 'pyret-mode (expand-file-name "vendor/pyret" (dir!))
  "major mode for pyret .arr files." t)

(add-to-list 'auto-mode-alist '("\\.arr\\'" . pyret-mode))

;; it predates prog-mode, so doom's code features need telling
(defun ro15rend/pyret-prog-h ()
  "run the hooks the upstream mode skips, so doom treats it as code."
  ;; its keys re-indent through tab, which only indents with this on
  (setq-local tab-always-indent t)
  (run-hooks 'prog-mode-hook 'after-change-major-mode-hook))

(derived-mode-add-parents 'pyret-mode '(prog-mode))
(add-hook 'pyret-mode-hook #'ro15rend/pyret-prog-h)
