;;; tests/modular.el -*- lexical-binding: t; -*-

;; run once per module with that module removed from config.el. everything that doesn't
;; need the removed module has to keep working.

(let ((without (getenv "TOADTEST_WITHOUT")))
  (dolist (spec `(("M-x agenda" ,(lambda () (ro15rend/org-agenda))
                   "lisp/org/commands" "lisp/org/files" "lisp/org/agenda")
                  ("M-x today" ,(lambda () (ro15rend/org-today))
                   "lisp/org/daily" "lisp/org/files")
                  ("M-x inbox" ,(lambda () (ro15rend/org-inbox))
                   "lisp/org/inbox" "lisp/org/files")
                  ("M-x urgent" ,(lambda () (ro15rend/org-urgent) (org-agenda-quit))
                   "lisp/org/commands" "lisp/org/files")
                  ("drawer" ,(lambda () (ro15rend/drawer) (ro15rend/drawer))
                   "lisp/dired")
                  ("open a .pv" ,(lambda () (spit "~/code/m.pv" "free c: channel.\nprocess 0\n")
                                   (find-file "~/code/m.pv")))
                  ("open a .arr" ,(lambda () (spit "~/code/m.arr" "fun f(): 1 end\n")
                                    (find-file "~/code/m.arr")))))
    (unless (member without (cddr spec))
      (check (format "%s still works" (car spec))
             (progn (funcall (nth 1 spec)) t))))
  (check "no errors logged" (null (logged-errors)))
  (check "no warnings buffer" (not (get-buffer "*Warnings*"))))
