;;; lisp/lib.el -*- lexical-binding: t; -*-

;;; paths

(defun ro15rend/dir (path)
  "PATH as an absolute directory name, with a trailing slash."
  (file-name-as-directory (expand-file-name path)))

(defun ro15rend/under-p (file dir)
  "non-nil when FILE sits inside DIR."
  (and file dir
       (file-in-directory-p (expand-file-name file) (ro15rend/dir dir))))

;;; buffers

(defvar ro15rend/secret-file-regexp
  "\\(?:/\\.env\\|\\.gpg\\'\\|\\.age\\'\\|authinfo\\|secret\\)"
  "file names that look like they hold secrets.")

(defun ro15rend/secret-file-p (&optional file)
  "non-nil when FILE, or this buffer's file, looks like it holds secrets."
  (when-let* ((file (or file buffer-file-name)))
    (string-match-p ro15rend/secret-file-regexp file)))

;; ghost-text completers check this, so they never fight a popup over TAB
(defun ro15rend/completion-popup-p ()
  "non-nil while an in-buffer completion popup, such as corfu's, is open."
  (bound-and-true-p completion-in-region-mode))

;;; keys

;; the override map, or evil shadows these. no nil state, so prompts keep their own keys
(defun ro15rend/bind-global (key command)
  "bind KEY to COMMAND in every evil state, so everywhere but prompts."
  (general-define-key :keymaps 'override
                      :states '(normal motion visual insert emacs operator replace)
                      key command))

(defun ro15rend/org-content-file-p (file)
  "Whether FILE or its symlink target names Org content, including archives."
  (when file
    (let ((case-fold-search t)
          (pattern "\\.org\\(?:_archive\\)?\\(?:\\.gpg\\)?\\'"))
      (or (string-match-p pattern file)
          (and (not (file-remote-p file))
               (string-match-p pattern (file-truename file)))))))
