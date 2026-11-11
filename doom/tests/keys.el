;;; tests/keys.el -*- lexical-binding: t; -*-

(defconst toadtest-keys
  '(("M-[" . centaur-tabs-backward) ("M-]" . centaur-tabs-forward)
    ("M-d" . ro15rend/drawer) ("M-f" . ro15rend/drawer-focus) ("M-e" . dired-jump)
    ("M-a" . ro15rend/org-agenda) ("M-t" . ro15rend/org-today)))

(defun toadtest-check-keys (where)
  (dolist (key toadtest-keys)
    (check (format "%s: %s runs %s" where (car key) (cdr key))
           (eq (binding (car key)) (cdr key)))))

(progn
  ;;; the keys work everywhere you edit

  (find-file "~/org/agenda.org")
  (evil-normal-state)
  (toadtest-check-keys "org, normal")
  (check "org, normal: M-p sets priority" (eq (binding "M-p") 'org-priority))
  (evil-insert-state)
  (toadtest-check-keys "org, insert")
  (evil-normal-state)

  (find-file "~/code/keys.txt")
  (evil-normal-state)
  (toadtest-check-keys "text, normal")
  (check "text: M-p is not org's" (not (eq (binding "M-p") 'org-priority)))
  (evil-insert-state)
  (toadtest-check-keys "text, insert")
  (evil-normal-state)

  ;;; prompts keep their own keys

  (let (seen)
    (run-at-time 0 nil
                 (lambda ()
                   (setq seen (mapcar (lambda (key) (cons key (binding key)))
                                      '("M-n" "M-p" "M-c" "M-d" "M-f" "M-e" "M-a" "M-t" "M-[" "M-]")))
                   (exit-minibuffer)))
    (read-string "test: ")
    (check "prompt: M-n is next history" (eq (cdr (assoc "M-n" seen)) 'next-history-element))
    (check "prompt: M-p is previous history" (eq (cdr (assoc "M-p" seen)) 'previous-history-element))
    (dolist (key toadtest-keys)
      (check (format "prompt: %s stays out" (car key))
             (not (eq (cdr (assoc (car key) seen)) (cdr key))))))

  (kill-new "https://paste.test/")
  (dolist (key '("C-v" "C-S-v"))
    (setq unread-command-events (listify-key-sequence (kbd (concat key " RET"))))
    (check (format "prompt: %s pastes" key)
           (equal (read-string "test: ") "https://paste.test/")))

  ;;; running them for real

  (ro15rend/org-today)
  (check "M-t path: today's log" (string-match-p "/org/logbook/" buffer-file-name))
  (ro15rend/org-agenda)
  (check "M-a page: agenda mode" (derived-mode-p 'org-agenda-mode))
  (check "agenda: M-p changes priority" (eq (binding "M-p") 'org-agenda-priority))
  (org-agenda-quit)
  (ro15rend/org-agenda-file-visit)
  (check "M-A path: agenda.org" (string-suffix-p "/org/agenda.org" buffer-file-name))
  (check "M-x inbox is a command" (commandp 'ro15rend/org-inbox))
  (check "M-x new week is a command" (commandp 'ro15rend/org-inbox-new-week))
  (check "M-x new-week is its short name" (eq (indirect-function 'new-week)
                                              (indirect-function 'ro15rend/org-inbox-new-week)))
  (check "M-x insert-link is a command" (commandp 'insert-link))
  (check "M-x unstick is a command" (commandp 'ro15rend/unstick))
  (check "capture off: M-c" (not (eq (binding "M-c") 'org-capture)))
  (check "capture: SPC X" (eq (lookup-key doom-leader-map "X") 'org-capture))
  (check "gt next tab" (eq (binding "g t") '+tabs:next-or-goto))
  (check "gT previous tab" (eq (binding "g T") '+tabs:previous-or-goto))

  ;;; workspaces

  (check "workspaces in order"
         (equal (+workspace-list-names) '("org" "code" "uni" "config" "misc")))
  (ro15rend/go "uni")
  (check "workspace: switching to uni" (equal (+workspace-current-name) "uni"))
  (ro15rend/go "org")

  ;;; drawer

  (find-file "~/org/agenda.org")
  (delete-other-windows)
  (ro15rend/drawer)
  (check "drawer: toggle shows it" (ro15rend/drawer-window))
  (check "drawer: toggle keeps focus" (not (ro15rend/drawer-p)))
  (check "drawer: on the right"
         (and (ro15rend/drawer-window)
              (window-at-side-p (ro15rend/drawer-window) 'right)))
  (ro15rend/drawer)
  (check "drawer: toggle hides it" (null (ro15rend/drawer-window)))
  (ro15rend/drawer-focus)
  (check "drawer: focus selects it" (ro15rend/drawer-p))
  (check "drawer: rooted at the workspace" (file-equal-p default-directory "~/org/"))
  (toadtest-check-keys "drawer")
  (check "drawer: . pins" (eq (binding ".") 'ro15rend/drawer-pin))
  (check "drawer: q closes" (eq (binding "q") 'ro15rend/drawer-close))
  (check "drawer: L enters" (eq (binding "L") 'dired-find-file))
  (check "drawer: H goes up" (eq (binding "H") 'dired-up-directory))
  (goto-char (point-min))
  (re-search-forward "queue")
  (check "drawer: l on a directory expands"
         (and (file-directory-p (dired-get-filename nil t))
              (eq (binding "l") 'dirvish-subtree-toggle)))
  (ro15rend/drawer-pin)
  (check "drawer: pin reroots" (file-equal-p default-directory "~/org/queue/"))
  (check "drawer: pin remembered"
         (equal (alist-get "org" ro15rend/drawer-pins nil nil #'equal)
                (expand-file-name "~/org/queue/")))
  (ro15rend/drawer-close)
  (check "drawer: q hides it" (null (ro15rend/drawer-window)))
  (check "drawer: q forgets the pin"
         (null (alist-get "org" ro15rend/drawer-pins nil nil #'equal)))
  (delete-other-windows)
  (ro15rend/drawer)
  (ro15rend/go "uni")
  (check "drawer: follows a workspace switch"
         (and (ro15rend/drawer-window)
              (with-selected-window (ro15rend/drawer-window)
                (file-equal-p default-directory "~/uni/"))))
  (ro15rend/drawer)
  (ro15rend/go "org")

  ;;; plain dirvish

  (delete-other-windows)
  (dired "~/org/")
  (check "dirvish: not the drawer" (not (ro15rend/drawer-p)))
  (toadtest-check-keys "dirvish")
  (check "dirvish: . is the usual binding" (eq (binding ".") 'dired-clean-directory))
  (check "dirvish: q quits" (eq (binding "q") 'dirvish-quit))
  (check "dirvish: L loads" (eq (binding "L") 'dired-do-load))
  (check "dirvish: H hardlinks" (eq (binding "H") 'dired-do-hardlink))
  (check "dirvish: keeps its M-n" (eq (binding "M-n") 'dirvish-narrow))
  (check "dirvish: N new file" (eq (binding "N") 'dired-create-empty-file))
  (check "dirvish: + new directory" (eq (binding "+") 'dired-create-directory))
  (check "dirvish: gh toggles dotfiles" (eq (binding "g h") 'dired-omit-mode))
  (dirvish-quit)

  (check "no errors logged" (null (logged-errors))))
