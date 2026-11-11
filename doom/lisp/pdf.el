;;; lisp/pdf.el -*- lexical-binding: t; -*-

;; pdfs open in a column on the right that holds nothing else, one tab each

(defun ro15rend/pdf-buffer-p (buffer &rest _)
  "whether BUFFER, a buffer or its name, is a pdf."
  (when-let* ((buffer (and buffer (get-buffer buffer))))
    (with-current-buffer buffer (derived-mode-p 'pdf-view-mode))))

;;; the column

(defun ro15rend/pdf-reserve (window)
  "keep WINDOW for pdfs. `display-buffer' clears this whenever it reuses a window."
  (set-window-dedicated-p window t))

;; right of the main area; doom rebuilds the alist, so add to both
(let ((rule '(ro15rend/pdf-buffer-p
              (display-buffer-reuse-mode-window display-buffer-in-direction)
              (direction . right)
              (window . main)
              (body-function . ro15rend/pdf-reserve))))
  (add-to-list 'display-buffer-alist rule)
  (add-to-list '+popup--display-buffer-alist rule))

;; switch-to-buffer skips display rules
(defun ro15rend/pdf-switch-a (fn buffer &rest args)
  "let the pdf rule place BUFFER when FN switches to it with ARGS."
  (let ((switch-to-buffer-obey-display-actions
         (or switch-to-buffer-obey-display-actions
             (ro15rend/pdf-buffer-p buffer))))
    (apply fn buffer args)))

(advice-add 'switch-to-buffer :around #'ro15rend/pdf-switch-a)

;; the drawer opens files inside its own window, so hand pdfs to the rule
(defun ro15rend/pdf-find-entry-h (entry &rest _)
  "show ENTRY through the pdf rule when it is a pdf."
  (when (and (string-suffix-p ".pdf" entry t)
             (not (file-directory-p entry)))
    (let ((buffer (find-file-noselect entry)))
      (when (ro15rend/pdf-buffer-p buffer)
        (pop-to-buffer buffer)
        t))))

(add-hook 'dirvish-find-entry-hook #'ro15rend/pdf-find-entry-h)

;; a window whose own buffer goes away can fall back to a hidden pdf
(defun ro15rend/pdf-evict-h (frame)
  "keep pdfs out of FRAME's other windows."
  (dolist (window (window-list frame 'no-minibuf))
    (when (and (not (window-dedicated-p window))
               (ro15rend/pdf-buffer-p (window-buffer window)))
      (set-window-buffer window (doom-fallback-buffer)))))

(add-hook 'window-buffer-change-functions #'ro15rend/pdf-evict-h)

;;; tabs

(defun ro15rend/pdf-tab-group ()
  "pdfs are one tab group, everything else groups as usual."
  (if (derived-mode-p 'pdf-view-mode)
      '("pdf")
    (centaur-tabs-buffer-groups)))

(setq centaur-tabs-buffer-groups-function #'ro15rend/pdf-tab-group)

;; centaur-tabs hides tabs in every reserved window
(defun ro15rend/pdf-hide-tab (buffer)
  "always show tabs for the pdf BUFFER, hide the rest as usual."
  (and (not (ro15rend/pdf-buffer-p buffer))
       (centaur-tabs-hide-tab buffer)))

(setq centaur-tabs-hide-tab-function #'ro15rend/pdf-hide-tab)

(defun ro15rend/pdf-next-tab-h ()
  "show another open pdf in this pdf's window, so closing a tab keeps the column."
  (when-let* (((get-buffer-window))
              (next (seq-find (lambda (buffer)
                                (and (not (eq buffer (current-buffer)))
                                     (ro15rend/pdf-buffer-p buffer)))
                              (if (bound-and-true-p persp-mode)
                                  (persp-buffer-list)
                                (buffer-list)))))
    (display-buffer next)))

(defun ro15rend/pdf-tabs-h ()
  "close this pdf like a tab."
  (add-hook 'kill-buffer-hook #'ro15rend/pdf-next-tab-h nil t))

(add-hook 'pdf-view-mode-hook #'ro15rend/pdf-tabs-h)

;; doom's kill-current-buffer switches buffers first, which a reserved window refuses
(defun ro15rend/pdf-kill-a (&rest _)
  "close a pdf directly. the next tab fills the column, the last one closes it."
  (when (ro15rend/pdf-buffer-p (current-buffer))
    (kill-buffer)
    t))

(advice-add 'kill-current-buffer :before-until #'ro15rend/pdf-kill-a)

;;; pdf-tools

;; nix ships epdfinfo beside its own copy of pdf-tools on the load path
(after! pdf-info
  (when-let* ((program (locate-file "epdfinfo" load-path nil 'executable)))
    (setq pdf-info-epdfinfo-program program)))

;; after pdf-tools, not pdf-view: doom sets fit-page in its own pdf-tools config
(after! pdf-tools
  (setq-default pdf-view-display-size 'fit-width))
