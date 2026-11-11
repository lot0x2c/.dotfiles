;;; lisp/org/commands.el -*- lexical-binding: t; -*-

;;; visiting

;; dynamic binding, org-agenda may not be loaded yet
(defvar org-agenda-overriding-header)
(defvar org-agenda-skip-unavailable-files)

(defun ro15rend/org-agenda ()
  "open the personal agenda page."
  (interactive)
  (ro15rend/go "org")
  (let ((org-agenda-skip-unavailable-files t))
    (org-agenda nil "r")))

(defun ro15rend/org-agenda-file-visit ()
  "visit the editable task list."
  (interactive)
  (ro15rend/org-open (ro15rend/org-agenda-file)))

(defun ro15rend/org-urgent ()
  "list every unfinished [#A] task across the agenda files."
  (interactive)
  (let ((org-agenda-overriding-header "urgent")
        (org-agenda-skip-unavailable-files t))
    (org-tags-view nil "PRIORITY=\"A\"/!")))

;;; sorting

(defun ro15rend/org-sort-tasks (method)
  "sort the tasks of the top level section at point using METHOD."
  (interactive
   (let ((choices '(("DONE last" . ?f) ("Priority" . ?p)
                    ("Alphabetical" . ?a) ("Scheduled date" . ?s)
                    ("Deadline" . ?d))))
     (list (cdr (assoc (completing-read "Sort section: " choices nil t) choices)))))
  (let ((mark-active nil))
    (org-back-to-heading t)
    (while (org-up-heading-safe))
    (org-sort-entries nil method
                      (when (eq method ?f)
                        (lambda () (if (org-entry-is-done-p) 1 0)))
                      (when (eq method ?f) #'<))))

;;; links

(defun ro15rend/insert-link (title url)
  "insert a link titled TITLE to URL, replacing the selection if any.
the prompts offer the selected text and a url on the clipboard."
  (interactive
   (let* ((clip (string-trim (or (ignore-errors (current-kill 0 t)) "")))
          (url (when (string-match-p "\\`[a-z+]+://[^ \t\n]+\\'" clip) clip)))
     (list (read-string "title: " (when (use-region-p)
                                    (buffer-substring-no-properties
                                     (region-beginning) (region-end))))
           ;; a default, not prefilled, so pasting the same url can't double it
           (read-string (format-prompt "link" url) nil nil url))))
  ;; outside org, org may not be loaded yet
  (require 'ol)
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (insert (org-link-make-string url title)))

;; keeps the older M-x name working
(defalias 'insert-link #'ro15rend/insert-link)

;;; keys

(ro15rend/bind-global "M-a" #'ro15rend/org-agenda)
(ro15rend/bind-global "M-A" #'ro15rend/org-agenda-file-visit)
(ro15rend/bind-global "M-t" #'ro15rend/org-today)
(after! org
  (map! :map org-mode-map
        "M-p" #'org-priority
        "M-*" #'org-ctrl-c-star))

(after! org
  (setq org-capture-templates
        `(("t" "Task" entry
           (file+function ,(ro15rend/org-inbox-file) ro15rend/org-inbox-week)
           "** TODO %?\n" :empty-lines 1))))

(map! :leader
      :desc "Capture task" "X" #'org-capture
      :prefix ("n" . "notes")
      :desc "Today" "t" #'ro15rend/org-today
      :desc "Weekly inbox" "i" #'ro15rend/org-inbox
      :desc "Agenda" "a" #'ro15rend/org-agenda
      :desc "Review and archive" "r" #'ro15rend/org-weekly-review)
