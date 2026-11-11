;;; lisp/places.el -*- lexical-binding: t; -*-

;; named workspace roots and switching between them

;;; places

(defconst ro15rend/places
  `(("org"    . "~/org/")
    ("code"   . "~/code/")
    ("uni"    . "~/uni/")
    ("config" . ,doom-user-dir)
    ("misc"   . "~/"))
  "workspace name to root directory. the order sets SPC TAB 1 2 3 4 5.")

(defun ro15rend/place-root (name)
  "expanded root of the place NAME, or nil."
  (when-let* ((root (cdr (assoc name ro15rend/places))))
    (ro15rend/dir root)))

(defun ro15rend/place-containing (path)
  "the most specific place containing PATH, or nil."
  (let (winner winner-length)
    (pcase-dolist (`(,name . ,_) ro15rend/places)
      (let ((root (ro15rend/place-root name)))
        (when (and (ro15rend/under-p path root)
                   (> (length root) (or winner-length -1)))
          (setq winner name
                winner-length (length root)))))
    winner))

(defun ro15rend/place-fresh-p ()
  "non-nil when the workspace has no real buffers."
  (not (seq-some #'doom-real-buffer-p (+workspace-buffer-list))))

;; doom quits dirvish before a switch, which can leave scratch behind
(defun ro15rend/place-resume ()
  "show a real buffer when the only window holds a non-real one."
  (when (and (not (doom-real-buffer-p (current-buffer)))
             (null (cdr (window-list))))
    (when-let* ((real (seq-find #'doom-real-buffer-p (+workspace-buffer-list))))
      (switch-to-buffer real))))

(defun ro15rend/go (name &optional dired)
  "switch to the place NAME.
with DIRED, open its root when the workspace is empty."
  (interactive (list (completing-read "place: " (mapcar #'car ro15rend/places) nil t)
                     t))
  (let ((root (or (ro15rend/place-root name)
                  (user-error "No place named %s" name))))
    (unless (file-directory-p root)
      (user-error "Place does not exist: %s" (abbreviate-file-name root)))
    (+workspace-switch name t)
    (if (and dired (ro15rend/place-fresh-p))
        (dired root)
      (ro15rend/place-resume))
    root))

