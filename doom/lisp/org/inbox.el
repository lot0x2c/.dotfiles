;;; lisp/org/inbox.el -*- lexical-binding: t; -*-

;; A weekly notebook, written once. Source tasks are shown by the agenda,
;; so refreshing a view never rewrites headings or moves somebody's notes.

(defconst ro15rend/org-week-chores '("read" "watch" "contact" "maint"))

(defun ro15rend/org-inbox-file ()
  "Return the weekly inbox path."
  (ro15rend/org-file "inbox.org"))

(defun ro15rend/org-inbox--add-week (week)
  "Insert WEEK above existing weeks without changing their contents."
  (goto-char (point-min))
  (if (re-search-forward "^\\* " nil t)
      (beginning-of-line)
    (goto-char (point-max))
    (unless (bolp) (insert "\n")))
  (let ((start (point)))
    (insert "* " week "\n** main quests\n")
    (dolist (chore ro15rend/org-week-chores)
      (insert "** TODO " chore "\n"))
    (insert "** worked upon\n** work upon\n")
    (goto-char start)))

(defun ro15rend/org-inbox-week ()
  "Go to the current week, creating it if necessary; never refresh old text."
  (widen)
  (let* ((week (format-time-string "%G-W%V"))
         (position (org-find-exact-headline-in-buffer week nil t)))
    (if position (goto-char position)
      (let ((clean (not (buffer-modified-p))))
        (ro15rend/org-inbox--add-week week)
        (when clean (save-buffer))))))

(defun ro15rend/org-inbox ()
  "Open this week's inbox, preserving all written notes."
  (interactive)
  (ro15rend/org-open (ro15rend/org-inbox-file))
  (ro15rend/org-inbox-week)
  (org-cycle-overview)
  (org-fold-show-subtree))

(defun ro15rend/org-inbox-new-week ()
  "Open the current week; repeated use never creates speculative future weeks."
  (interactive)
  (ro15rend/org-inbox))

(defalias 'new-week #'ro15rend/org-inbox-new-week)
