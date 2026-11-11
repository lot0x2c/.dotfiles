;;; tests/org-workflow.el -*- lexical-binding: t; -*-
(require 'org)

(let ((source (slurp "~/org/agenda.org")))
  (ro15rend/org-today)
  (check "today opens a dated file" (file-equal-p buffer-file-name (today-file)))
  (check "today does not mutate source tasks" (equal source (slurp "~/org/agenda.org")))
  (let ((text (buffer-string)))
    (ro15rend/org-today)
    (check "today is idempotent" (equal text (buffer-string))))
  (check "no cross-file completion hook"
         (not (memq 'ro15rend/org-log-sync-done-h org-after-todo-state-change-hook)))
  (check "navigation does not require a Git snapshot" (not (fboundp 'ro15rend/org-snapshot-today))))

(ro15rend/org-inbox)
(let ((before (buffer-string)))
  (ro15rend/org-inbox)
  (check "opening this week preserves its contents" (equal before (buffer-string))))
(goto-char (point-max))
(insert "\n** [[file:agenda.org::*A][A]]\nNotes for A\n*** child of A\n** [[file:agenda.org::*B][B]]\nNotes for B\n")
(let ((before (buffer-string)))
  (ro15rend/org-inbox)
  (check "opening inbox never reassigns notes to another task" (equal before (buffer-string)))
  (check "unsaved inbox edits remain unsaved" (buffer-modified-p)))
(save-buffer)

(spit "~/org/sys.org" "* TODO late-created task\n")
(ro15rend/org-agenda)
(check "agenda discovers optional files without config reload"
       (string-match-p "late-created task" (buffer-string)))
(org-agenda-quit)

(spit "~/org/projects/parent.org"
      "* TODO dated parent\nSCHEDULED: <2099-01-01 Thu>\n** TODO undated child\n")
(ro15rend/org-agenda)
(check "undated child of dated parent is visible" (string-match-p "undated child" (buffer-string)))
(org-agenda-quit)

(let ((source (slurp "~/org/agenda.org")))
  (with-current-buffer (find-file-noselect "~/org/sys.org") (goto-char (point-max)) (insert "unsaved\n"))
  (check "archive preflight refuses dirty files"
         (condition-case nil (progn (ro15rend/org-archive-old-done) nil) (user-error t)))
  (check "archive preflight changes no earlier source" (equal source (slurp "~/org/agenda.org"))))
