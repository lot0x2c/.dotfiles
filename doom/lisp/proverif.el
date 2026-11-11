;;; lisp/proverif.el -*- lexical-binding: t; -*-
(defconst ro15rend/proverif-dialects
  '(("\\.pv\\'"       proverif-pv-mode       "pitype")
    ("\\.pi\\'"       proverif-pi-mode       "pi")
    ("\\.horntype\\'" proverif-horntype-mode "horntype")
    ("\\.horn\\'"     proverif-horn-mode     "horn"))
  "file pattern, the mode proverif ships for it, and its -in format.
the four input languages proverif reads. the names differ on purpose:
a .pv file is the typed pi calculus, which proverif calls `pitype'.")

(defun ro15rend/proverif-dialect ()
  "the -in format for this buffer, the typed pi calculus by default."
  (or (nth 2 (seq-find (lambda (row) (eq (nth 1 row) major-mode))
                       ro15rend/proverif-dialects))
      "pitype"))

(defun ro15rend/proverif--words ()
  "read this dialect's keywords and builtins from the installed mode tables."
  (let ((stem (string-remove-suffix "-mode" (symbol-name major-mode))))
    (cl-loop for kind in '("kw" "builtin")
             for sym = (intern-soft (format "%s-%s" stem kind))
             when (and sym (boundp sym)) append (symbol-value sym))))

(defun ro15rend/proverif-capf ()
  "complete the proverif keyword at point.
allow other completion sources to supply user-defined names on a miss."
  (let ((bounds (or (bounds-of-thing-at-point 'symbol) (cons (point) (point)))))
    (list (car bounds) (cdr bounds) (ro15rend/proverif--words) :exclusive 'no)))

(defun ro15rend/proverif-prog-h ()
  "add comment commands, completion and prog hooks to the shipped mode.
it inherits from fundamental-mode, so prog hooks need to run explicitly."
  (setq-local comment-start "(* "
              comment-end " *)")
  (add-hook 'completion-at-point-functions #'ro15rend/proverif-capf 10 t)
  (run-hooks 'prog-mode-hook))

;; the system profile puts proverif.el on the load path, without a provide form
(when (locate-library "proverif")
  (pcase-dolist (`(,pattern ,mode ,_) ro15rend/proverif-dialects)
    (autoload mode "proverif" "major mode for a proverif model." t)
    (add-to-list 'auto-mode-alist (cons pattern mode))
    (derived-mode-add-parents mode '(prog-mode))
    (add-hook (intern (format "%s-hook" mode)) #'ro15rend/proverif-prog-h)))

;; check syntax on save, no proofs
(after! flycheck
  ;; quoted: loading this file expands macros, and expanding this one would
  ;; pull flycheck in at startup
  (eval
   '(flycheck-define-checker proverif
      "a proverif syntax and type checker, using proverif itself."
      :command ("proverif" "-parse-only"
                "-in" (eval (ro15rend/proverif-dialect))
                source)
      :error-patterns
      ((error line-start "file \"" (file-name) "\", line " line
              ", character" (opt "s") " " column (opt "-" (+ digit)) ":\n"
              (opt "Error: ") (message (+ not-newline)) line-end))
      :modes (proverif-pv-mode proverif-pi-mode
              proverif-horn-mode proverif-horntype-mode))
   t)
  (add-to-list 'flycheck-checkers 'proverif))
