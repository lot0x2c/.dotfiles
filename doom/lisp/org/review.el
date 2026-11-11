;;; lisp/org/review.el -*- lexical-binding: t; -*-

;; Explicit archival only. Navigation never changes Git history or archives tasks.

(defvar org-archive-location)

(defun ro15rend/org-review-files ()
  "the task files the weekly archive looks through."
  (delq nil
        (append (list (ro15rend/org-agenda-file) (ro15rend/org-file "sys.org")
                      (ro15rend/org-uni-file))
                (mapcan (lambda (dir)
                          (when (file-directory-p dir)
                            (directory-files dir t "\\.org\\'")))
                        (mapcar #'ro15rend/org-file '("projects" "sys"))))))

(defun ro15rend/org-review-open-descendant-p ()
  "non-nil when the subtree at point still has an open task."
  (save-excursion
    (let ((end (save-excursion (org-end-of-subtree t t))))
      (forward-line 1)
      (catch 'open
        (while (re-search-forward org-heading-regexp end t)
          (beginning-of-line)
          (when (equal (org-get-todo-state) "TODO")
            (throw 'open t))
          (forward-line 1))
        nil))))

(defun ro15rend/org-review-preflight (files)
  "Refuse FILES with unsaved or unwritable source/archive buffers before editing."
  (dolist (file files)
    (dolist (path (list file (ro15rend/org-file
                             (concat "archive/" (file-relative-name file org-directory)))))
      (when-let* ((buffer (find-buffer-visiting path)))
        (when (buffer-modified-p buffer)
          (user-error "Save %s before archiving" path)))
      (let ((parent path))
        (while (not (file-exists-p parent))
          (setq parent (directory-file-name (file-name-directory parent))))
        (unless (file-writable-p parent)
          (user-error "Archive path is not writable: %s" path))))))

(defun ro15rend/org-archive-old-done ()
  "archive DONE subtrees closed more than 14 days ago, and return how many."
  (require 'org-archive)
  (let ((cutoff (- (org-today) 14))
        (count 0)
        (files (seq-filter #'file-exists-p (ro15rend/org-review-files))))
    (ro15rend/org-review-preflight files)
    (dolist (file files)
      (when (file-exists-p file)
        (with-current-buffer (find-file-noselect file)
          (let (positions)
            (when (buffer-modified-p)
              (user-error "Save %s before the weekly archive" file))
            (org-map-entries
             (lambda ()
               (let ((closed (org-entry-get nil "CLOSED")))
                 (when (and closed
                            (not (ro15rend/org-review-open-descendant-p))
                            (< (org-time-string-to-absolute closed) cutoff))
                   (push (copy-marker (point)) positions))))
             "/DONE" 'file 'archive 'comment)
            (dolist (position positions)
              (goto-char position)
              (let* ((section (car (org-get-outline-path t)))
                     (relative (file-relative-name file org-directory))
                     (dest (ro15rend/org-file
                            (concat "archive/" relative)))
                     (org-archive-location
                      (concat dest "::* " (or section "Archived"))))
                (make-directory (file-name-directory dest) t)
                (org-archive-subtree)
                (cl-incf count))
              (set-marker position nil))
            (when (buffer-modified-p) (save-buffer))))))
    count))

(defun ro15rend/org-weekly-review ()
  "Explicitly archive old completed tasks, then open the weekly inbox."
  (interactive)
  (let ((count (ro15rend/org-archive-old-done)))
    (ro15rend/org-inbox)
    (message "Review ready; %d completed tasks archived" count)))
