;;; tests/start.el -*- lexical-binding: t; -*-

;; loaded after doom starts, in the throwaway emacs: state stays out of the real .local/

(let ((state (getenv "TOADTEST_STATE")))
  (setq savehist-file (concat state "savehist")
        recentf-save-file (concat state "recentf")
        save-place-file (concat state "saveplace")
        org-persist-directory (concat state "org-persist/")
        projectile-known-projects-file (concat state "projects.eld")
        projectile-cache-file (concat state "projectile.cache")
        dirvish-cache-dir (concat state "dirvish/")
        undo-tree-auto-save-history nil
        auto-save-default nil
        make-backup-files nil
        create-lockfiles nil
        backup-inhibited t)
  ;; tcp, so a long temp path can't exceed the unix socket limit
  (require 'server)
  (setq server-use-tcp t
        server-host "127.0.0.1"
        server-auth-dir state
        server-name "toadtest")
  (server-start))

(with-eval-after-load 'undo-tree
  (setq undo-tree-auto-save-history nil))

(defun toadtest-run (lib suite out)
  "load the helpers LIB, run the SUITE file, write the outcome to OUT."
  (load lib nil t)
  (condition-case err
      (load suite nil t)
    (error (toadtest-note-stop (error-message-string err))))
  (toadtest-write out)
  t)

;; Integration fixtures must never start network completion requests.
(with-eval-after-load 'minuet
  (advice-add 'minuet--openai-fim-compatible-complete :override #'ignore))
(with-eval-after-load 'copilot
  (advice-add 'ro15rend/copilot-server-p :override #'ignore))
