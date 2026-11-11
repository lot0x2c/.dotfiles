;;; lisp/minuet.el -*- lexical-binding: t; -*-

;; ghost-text completion in org files from a small model running in ollama.
;; nothing leaves this machine, so it is safe inside ~/org. the rest gets copilot.

;;; settings

(defun ro15rend/minuet-api-key ()
  "return a placeholder key; ollama ignores it but minuet insists on one."
  "ollama")

(after! minuet
  (setq minuet-provider 'openai-fim-compatible
        ;; one short suggestion per pause keeps the 7b model quick on a laptop
        minuet-n-completions 1
        minuet-context-window 512
        ;; requests are async, so a long wait never blocks typing. ollama unloads
        ;; the model after 10 idle minutes, and reloading the 7b took 26 s here
        minuet-request-timeout 60
        minuet-auto-suggestion-debounce-delay 0.5
        minuet-auto-suggestion-throttle-delay 1.0)
  (plist-put minuet-openai-fim-compatible-options :name "Ollama")
  (plist-put minuet-openai-fim-compatible-options :end-point "http://localhost:11434/v1/completions")
  ;; the 1.5b model was quicker but made up names; this one knows more
  (plist-put minuet-openai-fim-compatible-options :model "qwen2.5-coder:7b")
  ;; TERM may be unset when emacs starts from the window manager
  (plist-put minuet-openai-fim-compatible-options :api-key #'ro15rend/minuet-api-key)
  ;; A short, single-line completion; tokens are not words.
  (minuet-set-optional-options minuet-openai-fim-compatible-options :max_tokens 8)
  (minuet-set-optional-options minuet-openai-fim-compatible-options :stop ["\n"]))

;;; functions

(defun ro15rend/minuet-wanted-p ()
  "Non-nil only in an editable local .org file."
  (and buffer-file-name (not (file-remote-p buffer-file-name))
       (string-suffix-p ".org" buffer-file-name t)
       (derived-mode-p 'org-mode) (not buffer-read-only)))

(defun ro15rend/minuet-enable-h ()
  "Keep local completion confined to .org files, including after a rename."
  (if (ro15rend/minuet-wanted-p)
      (minuet-auto-suggestion-mode 1)
    (when (bound-and-true-p minuet-auto-suggestion-mode)
      (minuet-auto-suggestion-mode -1))))

(defun ro15rend/minuet-block-p ()
  "Block automatic requests outside .org or while a popup owns completion."
  (or (not (ro15rend/minuet-wanted-p)) (ro15rend/completion-popup-p)))

(defun ro15rend/minuet-guard-a (&rest _)
  "Keep manually invoked completions within .org files as well."
  (not (ro15rend/minuet-wanted-p)))

(add-hook 'find-file-hook #'ro15rend/minuet-enable-h)
(add-hook 'after-set-visited-file-name-hook #'ro15rend/minuet-enable-h)
(after! minuet
  (add-to-list 'minuet-auto-suggestion-block-predicates #'ro15rend/minuet-block-p)
  (dolist (function '(minuet-show-suggestion minuet-complete-with-minibuffer))
    (advice-add function :before-until #'ro15rend/minuet-guard-a)))

;;; keys

;; the map is only live while a suggestion shows, so TAB acts normally otherwise.
;; evil only activates a minor mode's state bindings when it renormalizes, and
;; this mode turns on in the middle of insert state
(after! minuet
  (add-hook 'minuet-active-mode-hook #'evil-normalize-keymaps)
  (map! :map minuet-active-mode-map
        :i "TAB"   #'minuet-accept-suggestion
        :i "<tab>" #'minuet-accept-suggestion
        :i "C-g"   #'minuet-dismiss-suggestion))
