;;; lisp/org/agenda.el -*- lexical-binding: t; -*-

;; one review page for dated and open tasks, each labelled with where it lives

(defun ro15rend/org-agenda-label ()
  "the source area of the agenda item at point."
  (let ((file (buffer-file-name)))
    (cond
     ;; both group tasks under top-level headings: agenda.org by area, uni.org by course
     ((and file (member (file-truename file)
                        (mapcar #'file-truename
                                (list (ro15rend/org-agenda-file) (ro15rend/org-uni-file)))))
      (save-excursion
        (when (org-before-first-heading-p)
          (org-next-visible-heading 1))
        (while (org-up-heading-safe))
        (or (org-get-heading t t t t) "agenda")))
     (file (file-name-base file))
     (t "agenda"))))

(defun ro15rend/org-agenda-skip-dated ()
  "skip a heading with a schedule or deadline in an agenda scan."
  (when (or (org-entry-get nil "SCHEDULED")
            (org-entry-get nil "DEADLINE"))
    (save-excursion (or (outline-next-heading) (point-max)) (point))))

(defun ro15rend/org-agenda-skip-other-week ()
  "skip an inbox entry filed under a week other than this one."
  (when (equal buffer-file-name (ro15rend/org-file "inbox.org"))
    (save-excursion
      (while (org-up-heading-safe))
      (let ((top (org-get-heading t t t t)))
        (when (and (string-match-p "\\`[0-9]\\{4\\}-W[0-9]\\{2\\}\\'" top)
                   (not (equal top (format-time-string "%G-W%V"))))
          (org-end-of-subtree t)
          (point))))))

;; each week brings its own chores, so older weeks would pile up here
(defun ro15rend/org-agenda-skip-open ()
  "skip what the open list leaves out: dated tasks and other weeks' inbox entries."
  (or (ro15rend/org-agenda-skip-dated)
      (ro15rend/org-agenda-skip-other-week)))

(defun ro15rend/org-agenda-item-area (item)
  "the source area of the rendered agenda ITEM."
  (when-let* ((marker (or (get-text-property 0 'org-hd-marker item)
                          (get-text-property 0 'org-marker item))))
    (when (marker-buffer marker)
      (with-current-buffer (marker-buffer marker)
        (save-excursion
          (goto-char marker)
          (ro15rend/org-agenda-label))))))

(defun ro15rend/org-agenda-compare-area (a b)
  "compare agenda entries A and B by their source area."
  (let ((area-a (ro15rend/org-agenda-item-area a))
        (area-b (ro15rend/org-agenda-item-area b)))
    (when (and area-a area-b (not (equal area-a area-b)))
      (if (string-lessp area-a area-b) -1 1))))

(after! org-agenda
  (setq org-agenda-custom-commands
        '(("r" "Review"
           ((agenda "" ((org-agenda-span 7)
                         (org-agenda-start-day "+0d")
                         (org-agenda-start-on-weekday nil)
                         (org-agenda-overriding-header "Due and upcoming")))
            (tags-todo "PRIORITY=\"A\""
                       ((org-agenda-overriding-header "Priority A")
                        (org-agenda-skip-function #'ro15rend/org-agenda-skip-other-week)))
            (alltodo "" ((org-agenda-overriding-header "Open without dates")
                          (org-agenda-skip-function
                           #'ro15rend/org-agenda-skip-open)
                          (org-agenda-cmp-user-defined
                           #'ro15rend/org-agenda-compare-area)
                          (org-agenda-sorting-strategy
                           '(user-defined-up priority-down))))))))
  ;; the label runs in each source buffer, where its outline is available
  (setq org-agenda-prefix-format
        '((agenda . " %(ro15rend/org-agenda-label) %?-12t% s")
          (todo . " %(ro15rend/org-agenda-label) ")
          (tags . " %(ro15rend/org-agenda-label) ")
          (search . " %(ro15rend/org-agenda-label) ")))
  (map! :map org-agenda-mode-map "M-p" #'org-agenda-priority))
