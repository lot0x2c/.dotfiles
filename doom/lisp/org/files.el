;;; lisp/org/files.el -*- lexical-binding: t; -*-

(setq org-directory (ro15rend/place-root "org"))

(defun ro15rend/org-file (relative)
  "RELATIVE expanded under `org-directory'."
  (expand-file-name relative org-directory))

(setq org-agenda-files
      (mapcar #'ro15rend/org-file
              '("agenda.org" "inbox.org" "sys.org" "uni.org" "projects/" "queue/" "sys/"))
      org-agenda-skip-unavailable-files t)

(defun ro15rend/org-agenda-file ()
  "the task list."
  (ro15rend/org-file "agenda.org"))

(defun ro15rend/org-uni-file ()
  "this semester's courses, one heading each with deadlines and a rubric."
  (ro15rend/org-file "uni.org"))

(defun ro15rend/org-daily-file ()
  "today's log file."
  (ro15rend/org-file (format-time-string "logbook/%Y-%m-%d.org")))

(defun ro15rend/org-open (file)
  "visit FILE in the org workspace."
  (ro15rend/go "org")
  (make-directory (file-name-directory file) t)
  (find-file file)
  (when (fboundp 'ro15rend/org-seed) (ro15rend/org-seed)))

;; one task state everywhere, done tasks get a timestamp, and files open on two
;; heading levels unless their own #+STARTUP says otherwise
(after! org
  (setq org-todo-keywords '((sequence "TODO" "|" "DONE"))
        org-log-done 'time
        org-startup-folded 'show2levels))
