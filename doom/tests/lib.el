;;; tests/lib.el -*- lexical-binding: t; -*-

;; refuse to run anywhere but the fake home: these tests write files
(unless (and (getenv "TOADTEST_HOME")
             (equal (expand-file-name "~/") (getenv "TOADTEST_HOME"))
             (or (not (bound-and-true-p org-directory))
                 (string-prefix-p (getenv "TOADTEST_HOME") (expand-file-name org-directory))))
  (error "not in the test home, stopping"))

(defvar toadtest-results nil)
(defvar toadtest-stopped nil)

(defmacro check (name form)
  "record whether FORM holds, under NAME. an error counts as a failure."
  `(condition-case err
       (push (if ,form (list t ,name) (list nil ,name)) toadtest-results)
     (error (push (list nil ,name (error-message-string err)) toadtest-results))))

(defun toadtest-note-stop (message)
  (setq toadtest-stopped message))

(defun toadtest-write (file)
  (let* ((rows (reverse toadtest-results))
         (bad (seq-remove #'car rows)))
    (with-temp-file file
      (if (or bad toadtest-stopped)
          (insert (format "FAILED %d of %d\n" (length bad) (length rows)))
        (insert (format "ok %d checks\n" (length rows))))
      (dolist (row bad)
        (insert (format "%s%s\n" (nth 1 row)
                        (if (nth 2 row) (format ": %s" (nth 2 row)) ""))))
      (when toadtest-stopped
        (insert (format "stopped after \"%s\": %s\n"
                        (or (nth 1 (car toadtest-results)) "the start")
                        toadtest-stopped))))))

(defun slurp (file)
  (with-temp-buffer
    (insert-file-contents (expand-file-name file))
    (buffer-string)))

(defun spit (file text)
  (let ((file (expand-file-name file)))
    (make-directory (file-name-directory file) t)
    (with-temp-file file (insert text))))

(defun drop (file)
  "close FILE's buffer without saving."
  (when-let* ((buffer (find-buffer-visiting (expand-file-name file))))
    (with-current-buffer buffer (set-buffer-modified-p nil))
    (kill-buffer buffer)))

(defun count-of (regexp text)
  (let ((n 0) (start 0))
    (while (string-match regexp text start)
      (setq n (1+ n) start (match-end 0)))
    n))

(defun this-week () (format-time-string "%G-W%V"))

(defun week-day (offset)
  "an org timestamp OFFSET days after this week's monday."
  (let ((weekday (string-to-number (format-time-string "%u"))))
    (format-time-string "<%Y-%m-%d %a>" (time-add nil (days-to-time (- offset (1- weekday)))))))

(defun this-week-text (text)
  "this week's section of the inbox TEXT, up to the next week, or \"\"."
  (if (string-match (format "^\\* %s\n\\(?:\\(?:[^*\n].*\\|\\*\\*.*\\)?\n\\)*" (this-week)) text)
      (match-string 0 text)
    ""))

(defun between (text from to)
  "the lines of TEXT between the lines FROM and TO, or \"\"."
  (if (string-match (format "^%s\n\\(\\(?:.*\n\\)*?\\)%s\n" (regexp-quote from) (regexp-quote to)) text)
      (match-string 1 text)
    ""))

(defun today-file () (format-time-string "~/org/logbook/%Y-%m-%d.org"))

(defun pdf-p (buffer)
  (with-current-buffer buffer (derived-mode-p 'pdf-view-mode)))

(defun normal-windows ()
  (seq-remove (lambda (window) (window-parameter window 'window-side))
              (window-list nil 'nomini)))

(defun pdf-window ()
  (seq-find (lambda (window) (pdf-p (window-buffer window))) (window-list nil 'nomini)))

(defun shown (file)
  (when-let* ((buffer (find-buffer-visiting (expand-file-name file))))
    (get-buffer-window buffer)))

(defun binding (key)
  (key-binding (kbd key) t))

(defun faced-chars ()
  "how many characters of this buffer have a face."
  (font-lock-ensure)
  (let ((n 0) (pos (point-min)))
    (while (< pos (point-max))
      (when (get-text-property pos 'face) (setq n (1+ n)))
      (setq pos (1+ pos)))
    n))

(defun logged-errors ()
  "error looking lines in *Messages*, without the old names upstream's pyret.el uses."
  (with-current-buffer "*Messages*"
    (let (found)
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward
                "^.*\\(error\\|warning\\|failed\\|void-\\|invalid\\|cannot\\|could not\\|wrong-\\).*$"
                nil t)
          (unless (string-match-p "vendor/pyret" (match-string 0))
            (push (match-string-no-properties 0) found))))
      (seq-uniq (nreverse found)))))
