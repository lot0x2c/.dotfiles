;;; lisp/org/daily.el -*- lexical-binding: t; -*-

;; Daily files are writing space. The agenda operates on original tasks;
;; there are no copied TODOs, title matching, or cross-file completion hooks.

(defun ro15rend/org-today ()
  "Open today's notes without running Git, archiving, or changing other files."
  (interactive)
  (ro15rend/org-open (ro15rend/org-daily-file)))
