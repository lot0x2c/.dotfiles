;;; lisp/org/template.el -*- lexical-binding: t; -*-

(defun ro15rend/org-seed ()
  "Initialize the current empty Org file after an explicit create/open command.
Use its neighboring template.org when present. Visiting a file in the
background never writes it. Existing content is never replaced."
  (when (and buffer-file-name (zerop (buffer-size))
             (ro15rend/under-p buffer-file-name org-directory))
    (let* ((name (file-name-base buffer-file-name))
           (template (expand-file-name "template.org" (file-name-directory buffer-file-name))))
      (if (and (not (equal template buffer-file-name)) (file-readable-p template))
          (insert (with-temp-buffer
                    (insert-file-contents template)
                    (replace-regexp-in-string "<name>" name (buffer-string) t t)))
        (insert (format "#+TITLE: %s\n\n" name)))
      (org-set-regexps-and-options)
      (org-cycle-set-startup-visibility)
      (goto-char (point-min))
      (save-buffer))))
