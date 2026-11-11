;;; lisp/editor.el -*- lexical-binding: t; -*-
(setq display-line-numbers-type 'relative
      shell-file-name (or (executable-find "bash") "/bin/sh"))

;; cursor stays centered
(setq scroll-margin 99999
      maximum-scroll-margin 0.5)

;; collect garbage when idle, and only after 64mb while working
(after! gcmh
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 64 1024 1024)))

;; snippet completion needs the snippets module, which is off
(after! lsp-mode
  (setq lsp-enable-snippet (modulep! :editor snippets)))

;; no word list installed, so ispell completion in text buffers just errors
(setq text-mode-ispell-word-completion nil)

(defface ro15rend/flash-face
  '((((background light)) :background "#a8e0d7" :extend nil)
    (((background dark))  :background "#17564d" :extend nil))
  "face the yank flash paints with.")

(defun ro15rend/flash-yank-a (beg end &rest _)
  "flash the yanked region from BEG to END."
  (pulse-momentary-highlight-region beg end 'ro15rend/flash-face))

;; no cache, so new files show up in project searches
(after! projectile
  (setq projectile-enable-caching nil))

;; copied text stays out of saved history
(after! savehist
  (setq savehist-additional-variables
        (delq 'register-alist
              (delq 'kill-ring savehist-additional-variables))))

(after! evil
  (setq evil-insert-state-cursor 'box)
  ;; doom's kill-current-buffer keeps the window and falls back to scratch
  (evil-ex-define-cmd "q[uit]" #'kill-current-buffer)
  (advice-add 'evil-yank :after #'ro15rend/flash-yank-a))

;; ctrl+v pastes in prompts, doom leaves it on scroll. C-S-j still pages lists
(map! :map minibuffer-local-map "C-v" #'yank)

;; doom starts flycheck at the first buffer, and the banner counts as one.
;; wait for a real file, so startup doesn't load it
(when (modulep! :checkers syntax)
  (remove-hook 'doom-first-buffer-hook #'global-flycheck-mode)
  (add-hook 'doom-first-file-hook #'global-flycheck-mode))

;; letters in the margin, no fringe icons
(after! flycheck
  (setq-default flycheck-indication-mode 'left-margin
                flycheck-fixable-indicator nil)
  (dolist (spec '((error   "E" flycheck-fringe-error)
                  (warning "W" flycheck-fringe-warning)
                  (info    "H" flycheck-fringe-info)))
    (setf (get (nth 0 spec) 'flycheck-margin-spec)
          (flycheck-make-margin-spec (nth 1 spec) (nth 2 spec))))
  (add-hook 'flycheck-mode-hook #'flycheck-refresh-fringes-and-margins))

;; doom runs the gutter update in a thread on emacs 30. timers run in whichever
;; thread waits, so a pdf-tools timer can fire there and fail on epdfinfo, which
;; belongs to the main thread. a git diff takes about 1 ms here
(after! diff-hl
  (setq diff-hl-update-async nil))

;; for the rare buffer stuck with a wrong keymap or in a stray recursive edit
(defun ro15rend/unstick ()
  "restore the major mode's keymap and leave stray recursive edits."
  (interactive)
  ;; viewers like pdf and dirvish swap keymaps on purpose
  (when-let* (((derived-mode-p 'text-mode 'prog-mode))
              (name (derived-mode-map-name major-mode))
              ((boundp name))
              (map (symbol-value name))
              ((not (eq (current-local-map) map))))
    (use-local-map map)
    (message "keymap restored"))
  (when (and (> (recursion-depth) 0) (not (active-minibuffer-window)))
    (top-level)))
