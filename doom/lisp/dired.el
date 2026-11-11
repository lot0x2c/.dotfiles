;;; lisp/dired.el -*- lexical-binding: t; -*-

;;; dired

;; dotfiles too, on top of doom's omit patterns
(after! dired-x
  (unless (string-prefix-p "\\`\\.\\|" dired-omit-files)
    (setq dired-omit-files (concat "\\`\\.\\|" dired-omit-files))))

;; set before the package loads, so its :set builds the icons. setopt here
;; would pull the whole customize ui in at startup
(setq dirvish-subtree-state-style 'plus)

;; dirvish hides the file creation keys, bring them back
(after! dirvish
  (map! :map (dired-mode-map dirvish-mode-map)
        :n "N" #'dired-create-empty-file
        :n "+" #'dired-create-directory
        ;; dotfiles on/off
        :n "gh" #'dired-omit-mode))

;;; drawer

(defconst ro15rend/drawer-fixed-places '("org" "config")
  "places whose drawer always stays at the place root.")

(defvar ro15rend/drawer-pins nil
  "workspace name to the directory pinned there with `.'.")

(defun ro15rend/drawer-root ()
  "the drawer root: the pin, else the project inside this place, else the place."
  (let* ((name (+workspace-current-name))
         (place (ro15rend/place-root name))
         (project (unless (member name ro15rend/drawer-fixed-places)
                    (doom-project-root))))
    (ro15rend/dir
     (cond ((alist-get name ro15rend/drawer-pins nil nil #'equal))
           ((and project
                 (or (null place)
                     (equal name (ro15rend/place-containing project))))
            project)
           (place)
           (project)
           (t default-directory)))))

;; auto-expand errors when the file is outside the root
(setq dirvish-side-auto-expand nil
      dirvish-side-width 45
      dirvish-side-display-alist '((side . right) (slot . 0))
      dirvish-side-attributes '(nerd-icons subtree-state)
      dirvish-side-mode-line-format '(:left (sort) :right (index)))

;; a workspace switch takes the drawer down, this says redraw it
(defvar ro15rend/drawer-wanted nil
  "whether the drawer belongs on screen.")

(defun ro15rend/drawer-window ()
  "the window showing the drawer, or nil."
  (require 'dirvish-side)
  (dirvish-side-session-visible-p))

(defun ro15rend/drawer-p ()
  "non-nil when the drawer is the selected window."
  (eq (selected-window) (ro15rend/drawer-window)))

;; keeps the buffer, so expanded subtrees survive a hide
(defun ro15rend/drawer--hide ()
  "take the drawer window off screen."
  (when-let* ((window (ro15rend/drawer-window)))
    (delete-window window)))

;; dirvish-side only selects a visible drawer, so hide first to reroot
(defun ro15rend/drawer--show ()
  "draw the drawer at `ro15rend/drawer-root' and return its window."
  (ro15rend/drawer--hide)
  (dirvish-side (ro15rend/drawer-root))
  (ro15rend/drawer-window))

(defun ro15rend/drawer ()
  "show or hide the drawer, keeping focus."
  (interactive)
  (if (setq ro15rend/drawer-wanted (null (ro15rend/drawer-window)))
      (save-selected-window (ro15rend/drawer--show))
    (ro15rend/drawer--hide)))

(defun ro15rend/drawer-focus ()
  "draw the drawer and select it."
  (interactive)
  (setq ro15rend/drawer-wanted t)
  (when-let* ((window (ro15rend/drawer--show)))
    (select-window window)))

(defun ro15rend/drawer-pin ()
  "root this workspace's drawer at the directory at point."
  (interactive)
  (let ((file (dired-get-filename nil t)))
    (setf (alist-get (+workspace-current-name) ro15rend/drawer-pins nil nil #'equal)
          (ro15rend/dir (if (and file (file-directory-p file)) file (dired-current-directory))))
    (ro15rend/drawer-focus)))

(defun ro15rend/drawer-close ()
  "hide the drawer and forget its tree and pin."
  (interactive)
  (setq ro15rend/drawer-wanted nil)
  (setf (alist-get (+workspace-current-name) ro15rend/drawer-pins nil t #'equal) nil)
  (save-selected-window
    (unless (ro15rend/drawer-window)
      (dirvish-side (ro15rend/drawer-root)))
    (when-let* ((window (ro15rend/drawer-window)))
      (with-selected-window window (dirvish-quit)))))

(defun ro15rend/drawer-reroot-h (&rest _)
  "redraw a wanted drawer at the new workspace's root."
  (when ro15rend/drawer-wanted
    (save-selected-window (ro15rend/drawer--show))))

(add-hook 'persp-activated-functions #'ro15rend/drawer-reroot-h)

;; drawer only. the last command is the usual binding
(after! dirvish
  (map! :map dirvish-mode-map
        :n "." (cmds! (ro15rend/drawer-p) #'ro15rend/drawer-pin
                      #'dired-clean-directory)
        :n "q" (cmds! (ro15rend/drawer-p) #'ro15rend/drawer-close
                      #'dirvish-quit)
        :n "l" (cmds! (and (ro15rend/drawer-p)
                           (file-directory-p (or (dired-get-filename nil t) "")))
                      #'dirvish-subtree-toggle
                      #'dired-find-file)
        :n "L" (cmds! (ro15rend/drawer-p) #'dired-find-file
                      #'dired-do-load)
        :n "H" (cmds! (ro15rend/drawer-p) #'dired-up-directory
                      #'dired-do-hardlink)))

(ro15rend/bind-global "M-d" #'ro15rend/drawer)
(ro15rend/bind-global "M-f" #'ro15rend/drawer-focus)
(ro15rend/bind-global "M-e" #'dired-jump)
