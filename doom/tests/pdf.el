;;; tests/pdf.el -*- lexical-binding: t; -*-

;; every pdf opens in the right column, that column holds only pdfs, and each pdf is a tab.

(defun toadtest-tabs-of (buffer)
  (with-current-buffer buffer
    (mapcar (lambda (tab) (buffer-name (car tab)))
            (centaur-tabs-tabs (centaur-tabs-current-tabset t)))))

(let* ((a (expand-file-name "~/org/a.pdf"))
       (b (expand-file-name "~/org/b.pdf"))
       (c (expand-file-name "~/org/c.pdf"))
       (d (expand-file-name "~/code/d.pdf"))
       (agenda (expand-file-name "~/org/agenda.org"))
       (inbox (expand-file-name "~/org/inbox.org")))
  (dolist (file (list a b c d))
    (copy-file "~/sample.pdf" file t))
  ;; the real ~/org is a git repo, and tabs group by project first
  (call-process "git" nil nil nil "init" "-q" (expand-file-name "~/org/"))

  ;;; the hook only touches pdfs

  (spit "~/org/plain.txt" "not a pdf\n")
  (check "hook: passes on a non-pdf"
         (null (ro15rend/pdf-find-entry-h (expand-file-name "~/org/plain.txt"))))
  (check "hook: the non-pdf was not visited"
         (null (find-buffer-visiting (expand-file-name "~/org/plain.txt"))))
  (make-directory "~/org/odd.pdf" t)
  (check "hook: a directory named .pdf is left alone"
         (null (ro15rend/pdf-find-entry-h (expand-file-name "~/org/odd.pdf"))))
  (delete-directory "~/org/odd.pdf")

  ;;; opening

  (delete-other-windows)
  (find-file agenda)
  (let ((main (selected-window)))
    (find-file a)
    (check "open: shown in a second window" (and (shown a) (not (eq (shown a) main))))
    (check "open: right of the main window"
           (> (window-pixel-left (shown a)) (window-pixel-left main)))
    (check "open: main keeps its file" (eq (window-buffer main) (find-buffer-visiting agenda)))
    (check "open: column reserved" (window-dedicated-p (shown a)))
    (with-current-buffer (find-buffer-visiting a)
      (check "open: pdf-view-mode" (derived-mode-p 'pdf-view-mode))
      (check "open: epdfinfo works" (> (pdf-info-number-of-pages) 0))
      (check "open: fits the width" (eq pdf-view-display-size 'fit-width)))

    (select-window main)
    (find-file b)
    (check "second pdf: same column" (and (shown b) (= 2 (length (normal-windows)))))
    (check "second pdf: main untouched" (eq (window-buffer main) (find-buffer-visiting agenda)))
    (check "second pdf: first still open" (buffer-live-p (find-buffer-visiting a)))
    (check "second pdf: column still reserved" (window-dedicated-p (shown b)))

    (select-window (shown b))
    (find-file a)
    (check "pdf from the column: same column" (and (shown a) (= 2 (length (normal-windows)))))
    (check "pdf from the column: still reserved" (window-dedicated-p (shown a)))

    (select-window main)
    (ro15rend/pdf-find-entry-h c)
    (check "from the drawer hook: same column" (and (shown c) (= 2 (length (normal-windows)))))
    (select-window main)
    (find-file-other-window a)
    (check "find-file-other-window: same column"
           (and (shown a) (= 2 (length (normal-windows)))
                (eq (window-buffer main) (find-buffer-visiting agenda))))
    (select-window main)
    (dired (expand-file-name "~/org/"))
    (goto-char (point-min))
    (re-search-forward "b\\.pdf")
    (dired-find-file)
    (check "dired: same column" (and (shown b) (= 2 (length (normal-windows)))))
    (when (derived-mode-p 'dired-mode) (dirvish-quit))
    (select-window main)
    (switch-to-buffer (find-buffer-visiting agenda))

    ;;; tabs

    (let* ((window (pdf-window))
           (tabs (toadtest-tabs-of (window-buffer window)))
           (format (with-current-buffer (window-buffer window)
                     (or tab-line-format header-line-format)))
           (drawn (substring-no-properties
                   (format-mode-line format nil window (window-buffer window)))))
      (check "tabs: the column lists all three pdfs"
             (seq-every-p (lambda (name) (member name tabs)) '("a.pdf" "b.pdf" "c.pdf")))
      (check "tabs: no org file among them" (not (member "agenda.org" tabs)))
      (check "tabs: bar drawn"
             (or (> (window-tab-line-height window) 0) (> (window-header-line-height window) 0)))
      (check "tabs: bar names the pdfs"
             (and (string-match-p "a\\.pdf" drawn) (string-match-p "b\\.pdf" drawn)
                  (string-match-p "c\\.pdf" drawn)))
      (check "tabs: bar has no org file" (not (string-match-p "agenda" drawn))))
    (check "tabs: main window's tabs have no pdfs"
           (let ((tabs (toadtest-tabs-of (window-buffer main))))
             (and (member "agenda.org" tabs)
                  (not (seq-some (lambda (name) (string-suffix-p ".pdf" name)) tabs)))))

    (select-window (pdf-window))
    (let ((column (selected-window))
          (before (window-buffer (selected-window))))
      (check "gt switches tabs in a pdf" (eq (binding "g t") '+tabs:next-or-goto))
      (check "gT switches tabs in a pdf" (eq (binding "g T") '+tabs:previous-or-goto))
      (centaur-tabs-forward)
      (check "tab switch: buffer changed" (not (eq (window-buffer column) before)))
      (check "tab switch: stayed in the column" (eq (selected-window) column))
      (check "tab switch: still a pdf" (pdf-p (window-buffer column)))
      (check "tab switch: still reserved" (window-dedicated-p column))
      (check "tab switch: main untouched" (eq (window-buffer main) (find-buffer-visiting agenda)))
      (centaur-tabs-backward)
      (check "tab switch back" (eq (window-buffer column) before))

      ;;; reserved

      (select-window column)
      (find-file inbox)
      (check "reserved: org file from the column lands in main" (eq (shown inbox) main))
      (check "reserved: column still a pdf" (pdf-p (window-buffer column)))
      (select-window column)
      (switch-to-buffer "*scratch*")
      (check "reserved: switch-to-buffer from the column" (pdf-p (window-buffer column)))
      (select-window main)
      (switch-to-buffer (find-buffer-visiting agenda))
      (check "reserved: display-buffer never picks it"
             (not (eq (display-buffer (get-buffer-create "*fixture*")) column)))
      (when-let* ((window (get-buffer-window "*fixture*")))
        (unless (eq window main) (ignore-errors (delete-window window))))
      (select-window main)
      (switch-to-buffer (find-buffer-visiting agenda))
      (select-window column)
      (ro15rend/org-today)
      (check "reserved: today from the column lands in main"
             (string-match-p "/logbook/" (or (buffer-file-name (window-buffer main)) "")))
      (check "reserved: column survives it" (pdf-p (window-buffer column)))

      ;;; pdfs stay out of the main window

      (select-window main)
      (find-file "~/code/first.txt")
      (find-file "~/code/second.txt")
      (previous-buffer)
      (redisplay t)
      (check "main: previous-buffer shows no pdf" (not (pdf-p (window-buffer main))))
      (switch-to-buffer (find-file-noselect "~/code/second.txt"))
      (dolist (buffer (buffer-list))
        (when (and (buffer-file-name buffer)
                   (not (pdf-p buffer))
                   (not (eq buffer (window-buffer main))))
          (kill-buffer buffer)))
      (kill-current-buffer)
      (redisplay t)
      (check "main: closing its last file shows no pdf" (not (pdf-p (window-buffer main))))
      (check "main: it shows the fallback" (eq (window-buffer main) (doom-fallback-buffer)))
      (check "main: column survives that" (and (window-live-p column) (pdf-p (window-buffer column))))
      (select-window main)
      (find-file agenda)

      ;;; closing tabs

      (select-window column)
      (let ((closing (window-buffer column)))
        (check "close: q closes the pdf" (eq (binding "q") 'kill-current-buffer))
        (kill-current-buffer)
        (check "close tab: buffer gone" (not (buffer-live-p closing)))
        (check "close tab: column stays" (window-live-p column))
        (check "close tab: shows another pdf" (and (window-live-p column) (pdf-p (window-buffer column))))
        (check "close tab: main untouched" (eq (window-buffer main) (find-buffer-visiting agenda))))
      (when (window-live-p column)
        (select-window column)
        (kill-current-buffer)
        (check "close second tab: still a pdf"
               (and (window-live-p column) (pdf-p (window-buffer column))))
        (when (window-live-p column)
          (select-window column)
          (kill-current-buffer)))
      (check "close last tab: column gone" (not (window-live-p column)))
      (check "close last tab: one window left" (= 1 (length (normal-windows))))
      (check "close last tab: main keeps its file"
             (eq (window-buffer (selected-window)) (find-buffer-visiting agenda)))
      (check "close last tab: no pdfs left" (not (seq-some #'pdf-p (buffer-list))))))

  ;;; reopening, the drawer, other workspaces

  (find-file a)
  (check "reopen: column is back" (and (shown a) (= 2 (length (normal-windows)))))
  (select-window (seq-find (lambda (w) (not (pdf-p (window-buffer w)))) (normal-windows)))
  (ro15rend/drawer)
  (find-file b)
  (check "with the drawer: same column" (and (shown b) (= 2 (length (normal-windows)))))
  (check "with the drawer: drawer untouched" (ro15rend/drawer-window))
  (select-window (seq-find (lambda (w) (not (pdf-p (window-buffer w)))) (normal-windows)))
  (ro15rend/drawer)
  (mapc (lambda (buffer) (when (pdf-p buffer) (kill-buffer buffer))) (buffer-list))
  (check "killing every pdf closes the column" (= 1 (length (normal-windows))))

  (find-file a)
  (ro15rend/go "code")
  (delete-other-windows)
  (find-file "~/code/note.txt")
  (let ((main (selected-window)))
    (find-file d)
    (check "other workspace: its own column" (and (shown d) (not (eq (shown d) main))))
    (check "other workspace: tabs list only its pdfs"
           (let ((tabs (toadtest-tabs-of (window-buffer (shown d)))))
             (and (member "d.pdf" tabs) (not (member "a.pdf" tabs))))))
  (ro15rend/go "org")
  (check "back in org: column still there" (shown a))
  (check "back in org: still reserved" (and (shown a) (window-dedicated-p (shown a))))

  (check "no errors logged" (null (logged-errors))))
