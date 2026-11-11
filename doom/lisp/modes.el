;;; lisp/modes.el -*- lexical-binding: t; -*-

;;; latex

;; compiled pdfs stay in emacs
(setq +latex-viewers '(pdf-tools))

;; whichever server is installed
(after! lsp-tex
  (cond ((executable-find "texlab")   (setq lsp-tex-server 'texlab))
        ((executable-find "digestif") (setq lsp-tex-server 'digestif))))

(defvar-local ro15rend/latex-fold-timer nil
  "this buffer's pending first fold.")

(defun ro15rend/latex-cancel-fold-h ()
  "cancel this buffer's pending fold."
  (when (timerp ro15rend/latex-fold-timer)
    (cancel-timer ro15rend/latex-fold-timer))
  (setq ro15rend/latex-fold-timer nil))

(defun ro15rend/latex-fold-buffer (buffer)
  "fold BUFFER if it is still a live TeX buffer."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq ro15rend/latex-fold-timer nil)
      (when (derived-mode-p 'TeX-mode)
        (TeX-fold-buffer)))))

(defun ro15rend/latex-fold-buffer-h ()
  "schedule one first fold in this buffer."
  (ro15rend/latex-cancel-fold-h)
  (add-hook 'kill-buffer-hook #'ro15rend/latex-cancel-fold-h nil t)
  (add-hook 'change-major-mode-hook #'ro15rend/latex-cancel-fold-h nil t)
  ;; pass the buffer: another one may be selected by the time emacs is idle
  (setq ro15rend/latex-fold-timer
        (run-with-idle-timer 0 nil #'ro15rend/latex-fold-buffer (current-buffer))))

(remove-hook 'TeX-mode-hook #'+latex-TeX-fold-buffer-h)
(add-hook 'TeX-mode-hook #'ro15rend/latex-fold-buffer-h)

;;; python

(set-formatter! 'ruff :modes '(python-mode python-ts-mode))

;;; web

(after! web-mode
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-enable-css-colorization t
        web-mode-enable-auto-quoting nil))
