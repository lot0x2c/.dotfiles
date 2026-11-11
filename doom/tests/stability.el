;;; stability.el --- Lifecycle and overlay regression checks -*- lexical-binding: t; -*-

(with-temp-buffer
  (ro15rend/latex-fold-buffer-h)
  (let ((first ro15rend/latex-fold-timer))
    (ro15rend/latex-fold-buffer-h)
    (check "LaTeX reschedule cancels the previous timer"
           (not (memq first timer-idle-list))))
  (let ((pending ro15rend/latex-fold-timer))
    (fundamental-mode)
    (check "Changing modes cancels the pending fold"
           (not (memq pending timer-idle-list))))
  (let ((folded nil))
    (cl-letf (((symbol-function 'TeX-fold-buffer) (lambda () (setq folded t))))
      (ro15rend/latex-fold-buffer (current-buffer)))
    (check "Delayed fold ignores a buffer in another mode" (not folded))))

(require 'tex)
(with-temp-buffer
  (let ((major-mode 'TeX-mode)
        (folded nil))
    (cl-letf (((symbol-function 'TeX-fold-buffer) (lambda () (setq folded t))))
      (ro15rend/latex-fold-buffer (current-buffer)))
    (check "Delayed fold still runs in TeX buffers" folded)))

(let ((buffer (generate-new-buffer " *fold-test*")) timer)
  (with-current-buffer buffer
    (ro15rend/latex-fold-buffer-h)
    (setq timer ro15rend/latex-fold-timer))
  (kill-buffer buffer)
  (check "Killing a buffer cancels its pending fold" (not (memq timer timer-idle-list))))

(require 'org)
(with-temp-buffer
  (org-mode)
  (check "No whole-buffer decoration on every command"
         (not (memq 'ro15rend/org-bullets-refresh post-command-hook))))
