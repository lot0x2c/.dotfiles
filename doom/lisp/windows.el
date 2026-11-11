;;; lisp/windows.el -*- lexical-binding: t; -*-

;; split only when asked
(setq pop-up-windows nil)

;;; tabs

(ro15rend/bind-global "M-[" #'centaur-tabs-backward)
(ro15rend/bind-global "M-]" #'centaur-tabs-forward)

;;; workspaces

;; workspace numbers follow place order
(setq +workspaces-main (caar ro15rend/places))

(defun ro15rend/places-order-a (names)
  "sort NAMES by their position in `ro15rend/places', unknown names last."
  (let ((order (mapcar #'car ro15rend/places)))
    (sort (copy-sequence names)
          (lambda (a b)
            (< (or (cl-position a order :test #'equal) most-positive-fixnum)
               (or (cl-position b order :test #'equal) most-positive-fixnum))))))

(advice-add '+workspace-list-names :filter-return #'ro15rend/places-order-a)

(defun ro15rend/places-init-h ()
  "create any missing place workspaces."
  (when (bound-and-true-p persp-mode)
    (dolist (name (mapcar #'car (cdr ro15rend/places)))
      (unless (+workspace-exists-p name)
        (+workspace-new name)))))

;; the direct call covers config reloads
(add-hook 'persp-mode-hook #'ro15rend/places-init-h t)
(when (bound-and-true-p persp-mode)
  (ro15rend/places-init-h))
