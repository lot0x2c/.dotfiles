;;; tests/settings.el -*- lexical-binding: t; -*-

;; does each setting stick once its package has loaded? doom's own config can overwrite them.

(progn
  ;;; startup stays lazy, checked before anything else loads

  (check "startup: flycheck waits for a file" (not (featurep 'flycheck)))
  (check "startup: customize ui not loaded" (not (featurep 'cus-edit)))
  (check "startup: calendar not loaded" (not (featurep 'calendar)))

  (find-file "~/org/agenda.org")
  (doom-run-hooks 'doom-first-input-hook)
  (dolist (feature '(org org-capture org-agenda evil flycheck projectile savehist dired dired-x
                     dirvish dirvish-side dirvish-subtree lsp-mode lsp-tex web-mode tex
                     pdf-tools pdf-info pdf-view doom-modeline nerd-icons nyan-mode
                     centaur-tabs persp-mode gcmh))
    (check (format "loads: %s" feature) (require feature nil t)))

  ;;; editor.el

  (check "line numbers relative" (eq display-line-numbers-type 'relative))
  (check "shell is bash" (string-suffix-p "/bash" shell-file-name))
  (check "scroll: cursor stays centered" (and (= scroll-margin 99999) (= maximum-scroll-margin 0.5)))
  (check "scroll: doom's conservatively holds" (= scroll-conservatively 10))
  (check "gcmh idle auto" (eq gcmh-idle-delay 'auto))
  (check "gcmh factor" (= gcmh-auto-idle-delay-factor 10))
  (check "gcmh 64mb" (= gcmh-high-cons-threshold (* 64 1024 1024)))
  (check "lsp snippets off" (null lsp-enable-snippet))
  (check "ispell completion off" (null text-mode-ispell-word-completion))
  (check "projectile cache off" (null projectile-enable-caching))
  (check "kill-ring not saved" (not (memq 'kill-ring savehist-additional-variables)))
  (check "registers not saved" (not (memq 'register-alist savehist-additional-variables)))
  (check "box cursor in insert" (eq evil-insert-state-cursor 'box))
  (check ":q kills the buffer" (eq (evil-ex-binding "q") 'kill-current-buffer))
  (check "yank flash runs"
         (with-temp-buffer
           (insert "hello")
           (ro15rend/flash-yank-a (point-min) (point-max))
           (advice-member-p 'ro15rend/flash-yank-a 'evil-yank)))
  (check "flycheck: letters in the margin" (eq (default-value 'flycheck-indication-mode) 'left-margin))
  (check "flycheck: E margin" (string-match-p "E" (format "%S" (get 'error 'flycheck-margin-spec))))
  (check "flycheck: W margin" (string-match-p "W" (format "%S" (get 'warning 'flycheck-margin-spec))))
  (check "flycheck: H margin" (string-match-p "H" (format "%S" (get 'info 'flycheck-margin-spec))))
  (check "esc hook is plain doom" (not (memq 'ro15rend/unstick-h doom-escape-hook)))
  (with-temp-buffer
    (text-mode)
    (use-local-map (make-sparse-keymap))
    (ro15rend/unstick)
    (check "unstick: restores a wrong keymap" (eq (current-local-map) text-mode-map)))
  (with-temp-buffer
    (special-mode)
    (let ((map (make-sparse-keymap)))
      (use-local-map map)
      (ro15rend/unstick)
      (check "unstick: leaves viewers' keymaps alone" (eq (current-local-map) map))))

  ;;; gutter

  (require 'diff-hl)
  (check "gutter: updates without a thread" (null diff-hl-update-async))

  ;;; windows

  (check "no splitting unasked" (null pop-up-windows))
  (check "main workspace is org" (equal +workspaces-main "org"))
  (check "sort advice on" (advice-member-p 'ro15rend/places-order-a '+workspace-list-names))

  ;;; org

  (check "org-directory" (string-suffix-p "/org/" org-directory))
  (check "todo keywords" (equal org-todo-keywords '((sequence "TODO" "|" "DONE"))))
  (check "done gets a time" (eq org-log-done 'time))
  ;; a heading's line start, since its fold begins at the newline ending it
  (cl-flet ((hidden-p (regexp)
              (save-excursion
                (goto-char (point-min))
                (re-search-forward regexp)
                (invisible-p (match-beginning 0)))))
    (spit "~/code/levels.org" "* one\n** two\n*** three\nbody\n")
    (with-current-buffer (find-file-noselect "~/code/levels.org")
      (check "org: opens on two levels"
             (and (not (hidden-p "^\\*\\* two")) (hidden-p "^\\*\\*\\* three")))
      (kill-buffer))
    (drop "~/code/levels.org")
    (spit "~/code/levels.org" "#+STARTUP: overview\n* one\n** two\n*** three\n")
    (with-current-buffer (find-file-noselect "~/code/levels.org")
      (check "org: a file's own #+STARTUP wins" (hidden-p "^\\*\\* two"))
      (kill-buffer)))
  (drop "~/code/levels.org")
  (delete-file (expand-file-name "~/code/levels.org"))
  (check "places: krea is gone" (null (ro15rend/place-root "krea")))
  (check "places: uni" (equal (ro15rend/place-root "uni") (expand-file-name "~/uni/")))

  ;;; dired

  (check "dotfiles hidden" (string-prefix-p "\\`\\.\\|" dired-omit-files))
  (check "doom's omit patterns kept" (string-match-p "DS_Store" dired-omit-files))
  (check "subtree plus style" (eq dirvish-subtree-state-style 'plus))
  (check "subtree plus icons"
         (equal (cons (substring-no-properties (car dirvish-subtree--state-icons))
                      (substring-no-properties (cdr dirvish-subtree--state-icons)))
                '("-" . "+")))
  (check "drawer no auto expand" (null dirvish-side-auto-expand))
  (check "drawer width" (= dirvish-side-width 45))
  (check "drawer on the right" (equal dirvish-side-display-alist '((side . right) (slot . 0))))
  (check "drawer attributes" (equal dirvish-side-attributes '(nerd-icons subtree-state)))
  (check "drawer modeline" (equal dirvish-side-mode-line-format '(:left (sort) :right (index))))

  ;;; pdf

  (check "pdf fit-width" (eq (default-value 'pdf-view-display-size) 'fit-width))
  (check "pdf rule in both alists"
         (and (assq 'ro15rend/pdf-buffer-p display-buffer-alist)
              (assq 'ro15rend/pdf-buffer-p +popup--display-buffer-alist)))
  (check "epdfinfo found"
         (and pdf-info-epdfinfo-program (file-executable-p pdf-info-epdfinfo-program)))

  ;;; modes

  (check "latex opens in pdf-tools" (equal +latex-viewers '(pdf-tools)))
  (check "latex server" (eq lsp-tex-server 'texlab))
  (spit "~/code/page.html" "<p>x</p>\n")
  (find-file "~/code/page.html")
  (check "web: web-mode" (eq major-mode 'web-mode))
  (check "web: indent 2" (and (= web-mode-markup-indent-offset 2)
                              (= web-mode-css-indent-offset 2)
                              (= web-mode-code-indent-offset 2)))
  (check "web: css colorization on" web-mode-enable-css-colorization)
  (check "web: auto-quoting off" (null web-mode-enable-auto-quoting))

  ;;; rss stays off for now

  (check "rss: module off" (not (modulep! :app rss)))
  (check "rss: elfeed not loaded" (not (featurep 'elfeed)))

  ;;; minuet

  (let ((org-buffer (find-file-noselect "~/org/agenda.org")))
    (check "minuet: loaded by the first org file" (featurep 'minuet))
    (check "minuet: suggestions on in org"
           (buffer-local-value 'minuet-auto-suggestion-mode org-buffer))
    (check "minuet: local ollama endpoint"
           (equal (plist-get minuet-openai-fim-compatible-options :end-point)
                  "http://localhost:11434/v1/completions"))
    (check "minuet: 7b model"
           (equal (plist-get minuet-openai-fim-compatible-options :model) "qwen2.5-coder:7b"))
    (check "minuet: provider" (eq minuet-provider 'openai-fim-compatible))
    (check "minuet: short token budget"
           (= (plist-get (plist-get minuet-openai-fim-compatible-options :optional) :max_tokens) 8))
    (check "minuet: waits out a model reload" (>= minuet-request-timeout 30))
    (check "minuet: stops at the end of the line"
           (equal (plist-get (plist-get minuet-openai-fim-compatible-options :optional) :stop) ["\n"]))
    (check "minuet: key without TERM" (equal (minuet--get-api-key #'ro15rend/minuet-api-key) "ollama"))
    (check "minuet: yields to the completion popup"
           (memq #'ro15rend/minuet-block-p minuet-auto-suggestion-block-predicates))
    (check "minuet: off in code" (not (memq #'ro15rend/minuet-enable-h prog-mode-hook)))
    (check "minuet: TAB untouched without a suggestion"
           (with-current-buffer org-buffer
             (evil-insert-state)
             (not (eq (key-binding (kbd "TAB")) 'minuet-accept-suggestion))))
    (check "minuet: TAB accepts a shown suggestion"
           (with-current-buffer org-buffer
             (evil-insert-state)
             (minuet-active-mode 1)
             (prog1 (eq (key-binding (kbd "TAB")) 'minuet-accept-suggestion)
               (minuet-active-mode -1))))
    (check "minuet: no suggestions in a secret file"
           (with-temp-buffer
             (let ((buffer-file-name "/h/.env"))
               (ro15rend/minuet-enable-h))
             (not minuet-auto-suggestion-mode))))

  ;;; secrets, shared by both completers

  (dolist (name '("/h/.env" "/h/.env.local" "/h/a.gpg" "/h/.authinfo" "/h/my-secrets.org"))
    (check (format "secret: %s" name) (ro15rend/secret-file-p name)))
  (dolist (name '("/h/org/agenda.org" "/h/code/main.py"))
    (check (format "not secret: %s" name) (not (ro15rend/secret-file-p name))))

  ;;; copilot

  (require 'copilot)
  (cl-flet ((wanted-in (mode file &optional src-block)
              (with-temp-buffer
                ;; temp buffers are named " *temp*", which the gate treats as internal
                (rename-buffer "copilot-test" t)
                (setq buffer-file-name (expand-file-name file)
                      default-directory (file-name-directory buffer-file-name))
                (delay-mode-hooks (funcall mode))
                (when src-block (setq-local org-src-mode t))
                (prog1 (ro15rend/copilot-wanted-p)
                  (setq buffer-file-name nil)))))
    (check "copilot: no indentation warning" copilot-indent-offset-warning-disable)
    (check "copilot: python" (wanted-in #'python-mode "~/code/a.py"))
    (check "copilot: c" (wanted-in #'c-mode "~/code/a.c"))
    (check "copilot: haskell" (wanted-in #'haskell-mode "~/code/a.hs"))
    (check "copilot: elisp" (wanted-in #'emacs-lisp-mode "~/code/a.el"))
    (check "copilot: plain text" (wanted-in #'text-mode "~/code/notes.txt"))
    (check "copilot: never org-mode" (not (wanted-in #'org-mode "~/code/a.org")))
    (check "copilot: never a .org file in another mode"
           (not (wanted-in #'fundamental-mode "~/code/a.org")))
    (check "copilot: never an org archive" (not (wanted-in #'text-mode "~/code/a.org_archive")))
    (check "copilot: never a block opened from org" (not (wanted-in #'python-mode "~/code/a.py" t)))
    (check "copilot: code inside ~/org" (wanted-in #'haskell-mode "~/org/library/lab/haskell/first.hs"))
    (check "copilot: latex" (wanted-in #'LaTeX-mode "~/code/paper.tex"))
    (check "copilot: latex inside ~/org" (wanted-in #'LaTeX-mode "~/org/me/resume/resume.tex"))
    (check "copilot: non-org prose inside ~/org" (wanted-in #'text-mode "~/org/notes.txt"))
    (check "copilot: non-org commit message"
           (wanted-in #'text-mode "~/org/.git/COMMIT_EDITMSG"))
    (check "copilot: never a secret file" (not (wanted-in #'python-mode "~/code/secrets.py"))))
  (check "copilot: never an unsaved buffer in ~/org"
         (with-temp-buffer
           (setq default-directory (expand-file-name "~/org/"))
           (python-mode)
           (ro15rend/copilot-forbidden-p)))

  ;; the hard stop: record what would reach the server instead of sending it
  (cl-flet ((sent-from (mode file)
              (let (sent)
                ;; copilot--notify is a macro, so stub what it expands into
                (cl-letf (((symbol-function 'copilot--connection-alivep) #'always)
                          ((symbol-function 'jsonrpc-notify)
                           (lambda (_connection method &rest _) (push method sent))))
                  (with-temp-buffer
                    (setq buffer-file-name (expand-file-name file)
                          default-directory (file-name-directory buffer-file-name))
                    (delay-mode-hooks (funcall mode))
                    (copilot--ensure-doc-open)
                    (setq copilot--opened-buffers (delq (current-buffer) copilot--opened-buffers)
                          buffer-file-name nil)))
                sent)))
    (check "copilot stop: the send function still exists" (fboundp 'copilot--ensure-doc-open))
    (check "copilot stop: code is sent" (memq 'textDocument/didOpen (sent-from #'python-mode "~/code/a.py")))
    (check "copilot stop: an org file is never sent" (null (sent-from #'org-mode "~/code/a.org")))
    (check "copilot stop: an org file in ~/org is never sent" (null (sent-from #'org-mode "~/org/agenda.org")))
    (check "copilot stop: non-org prose is eligible" (memq 'textDocument/didOpen (sent-from #'text-mode "~/org/notes.txt")))
    ;; the fixture ~/org is a git repo, so copilot would take it as the root
    (check "copilot stop: premise, unfiltered root is ~/org"
           (with-temp-buffer
             (setq default-directory (expand-file-name "~/org/lab/"))
             (equal (file-name-as-directory (copilot--project-root default-directory))
                    (file-name-as-directory (file-truename "~/org/")))))
    (let ((sent (sent-from #'python-mode "~/org/lab/a.py")))
      (check "copilot stop: code in ~/org is sent" (memq 'textDocument/didOpen sent))
      (check "copilot stop: without ~/org as its workspace"
             (not (memq 'workspace/didChangeWorkspaceFolders sent)))))
  (check "copilot root: ~/org is dropped" (null (ro15rend/copilot-root-a (expand-file-name "~/org/"))))
  (check "copilot root: a root holding ~/org is dropped" (null (ro15rend/copilot-root-a (expand-file-name "~/"))))
  (check "copilot root: projects stay outside sandbox"
         (null (ro15rend/copilot-root-a (expand-file-name "~/code/x/"))))
  (check "copilot root: both root functions filtered"
         (and (advice-member-p #'ro15rend/copilot-root-a 'copilot--workspace-root)
              (advice-member-p #'ro15rend/copilot-root-a 'copilot--directory-workspace-root)))
  (check "copilot: M-x copilot-mode in org turns itself off"
         (with-temp-buffer
           (org-mode)
           (copilot-mode 1)
           (not copilot-mode)))
  (check "copilot: waits for a pause" (= copilot-idle-delay 0.3))
  (check "copilot: yields to the completion popup"
         (memq #'ro15rend/completion-popup-p copilot-disable-predicates))
  (check "copilot: TAB accepts on its overlay"
         (eq (keymap-lookup copilot-completion-map "TAB") 'copilot-accept-completion))
  (check "copilot: no server, no mode, no error"
         (with-temp-buffer
           (setq buffer-file-name (expand-file-name "~/code/b.py"))
           (let ((copilot-server-executable "/nonexistent/copilot-language-server")
                 (copilot-install-dir "/nonexistent"))
             (delay-mode-hooks (python-mode))
             (ro15rend/copilot-enable-h))
           (prog1 (not copilot-mode)
             (setq buffer-file-name nil))))

  ;;; extras

  (check "speed-type command" (fboundp 'speed-type-text))
  (check "proverif covers all four"
         (and (rassq 'proverif-pv-mode auto-mode-alist)
              (rassq 'proverif-pi-mode auto-mode-alist)
              (rassq 'proverif-horn-mode auto-mode-alist)
              (rassq 'proverif-horntype-mode auto-mode-alist)))

  (check "no errors logged" (null (logged-errors)))
  (check "no warnings buffer" (not (get-buffer "*Warnings*"))))
