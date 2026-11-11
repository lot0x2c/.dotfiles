;;; lisp/copilot.el -*- lexical-binding: t; -*-

;; Completion only. The isolated server cannot read host notes or projects.
;; Emacs sends eligible file buffers; the transport gate also covers manual calls.

(defun ro15rend/copilot-forbidden-p ()
  "Non-nil for Org content, secrets, remote files and non-file buffers."
  (or (null buffer-file-name)
      (file-remote-p buffer-file-name)
      (derived-mode-p 'org-mode)
      (bound-and-true-p org-src-mode)
      (ro15rend/org-content-file-p buffer-file-name)
      (ro15rend/secret-file-p)))

(defun ro15rend/copilot-wanted-p ()
  "Whether this editable file should get Copilot completion."
  (and (not (ro15rend/copilot-forbidden-p))
       (not buffer-read-only) (not (minibufferp))))

(defun ro15rend/copilot-server-p ()
  "Whether the isolated server is installed; never fall back to a bare server."
  (executable-find "copilot-isolated"))

(defun ro15rend/copilot-enable-h ()
  "Enable Copilot only for eligible files and only with the isolated server."
  (when (and (ro15rend/copilot-wanted-p) (ro15rend/copilot-server-p))
    (copilot-mode 1)))

(defun ro15rend/copilot-refuse-h ()
  "Turn off Copilot if a file changes into excluded content."
  (when (and (bound-and-true-p copilot-mode)
             (ro15rend/copilot-forbidden-p))
    (copilot-mode -1)))

(defun ro15rend/copilot-mode-guard-a (&optional argument)
  "Refuse enabling the minor mode before it can start a server."
  (and (not (eq argument -1)) (ro15rend/copilot-forbidden-p)))

(defun ro15rend/copilot-guard-a (&rest _)
  "Block completion entry points in excluded buffers."
  (ro15rend/copilot-forbidden-p))

(defun ro15rend/copilot-root-a (_root)
  "Do not advertise any host project to the isolated server."
  nil)

(defun ro15rend/copilot-document-allowed-p (params)
  "Whether PARAMS describe a currently eligible file buffer."
  (let ((uri (plist-get (plist-get params :textDocument) :uri)))
    (and (stringp uri)
         (seq-some
          (lambda (buffer)
            (with-current-buffer buffer
              (and (not (ro15rend/copilot-forbidden-p))
                   (equal uri (copilot--get-uri)))))
          (buffer-list)))))

(defun ro15rend/copilot-send-a (send connection &rest args)
  "Restrict Copilot CONNECTION to authentication and eligible completion traffic.
Other JSON-RPC clients are unchanged. Chat, tools and filesystem requests are
outside this completion-only integration. This is the last Emacs send boundary."
  (if (not (eq connection (bound-and-true-p copilot--connection)))
      (apply send connection args)
    (let* ((method (plist-get args :method))
           (name (string-remove-prefix ":" (format "%s" method)))
           (params (plist-get args :params))
           (document (member name '("textDocument/didOpen" "textDocument/didChange"
                                    "textDocument/didFocus" "textDocument/didClose"
                                    "textDocument/inlineCompletion")))
           (allowed
            (if document
                (ro15rend/copilot-document-allowed-p params)
              (member name '("initialize" "initialized" "shutdown" "exit"
                             "signInInitiate" "signInConfirm" "signOut" "checkStatus"
                             "$/cancelRequest" "copilot/models"
                             "workspace/didChangeConfiguration" "notifyAccepted"
                             "notifyShown" "notifyRejected")))))
      ;; Responses contain only our restricted request handler's result.
      (when (or (null method) allowed)
        (apply send connection args)))))

(defun ro15rend/copilot-request-a (_connection _method _params)
  "Deny server-initiated editor tools and filesystem access."
  :json-null)

(add-hook 'find-file-hook #'ro15rend/copilot-enable-h)
(add-hook 'after-change-major-mode-hook #'ro15rend/copilot-refuse-h)
(add-hook 'after-set-visited-file-name-hook #'ro15rend/copilot-refuse-h)

(after! copilot
  (setq copilot-server-executable "copilot-isolated"
        copilot-idle-delay 0.3
        copilot-indent-offset-warning-disable t
        copilot-mcp-servers nil)
  (add-to-list 'copilot-disable-predicates #'ro15rend/completion-popup-p)
  (add-hook 'copilot-mode-hook #'ro15rend/copilot-refuse-h)
  (advice-add 'copilot-mode :before-until #'ro15rend/copilot-mode-guard-a)
  (dolist (function '(copilot-complete copilot--ensure-doc-open))
    (advice-add function :before-until #'ro15rend/copilot-guard-a))
  (dolist (function '(copilot--workspace-root copilot--directory-workspace-root))
    (advice-add function :filter-return #'ro15rend/copilot-root-a))
  (advice-add 'jsonrpc-connection-send :around #'ro15rend/copilot-send-a)
  (advice-add 'copilot--handle-request :override #'ro15rend/copilot-request-a))
