;;; lisp/org/appearance.el -*- lexical-binding: t; -*-

;; links take the colour of whatever they sit in, heading or body
(custom-set-faces!
  '(org-date :underline nil)
  '(org-link :foreground unspecified :underline t))

;; pink and teal groups make heading depth easy to tell apart
(custom-set-faces!
  '(org-level-1 :foreground "#008b8b" :weight bold)
  '(org-level-2 :foreground "#b3265e" :weight normal)
  '(org-level-3 :foreground "#dc286e" :weight normal)
  '(org-level-4 :foreground "#e76599" :weight normal)
  '(org-level-5 :foreground "#00565c" :weight normal)
  '(org-level-6 :foreground "#008b8b" :weight normal)
  '(org-level-7 :foreground "#49a8aa" :weight normal)
  '(org-level-8 :foreground "#49a8aa" :weight normal))

(after! org
  (setq org-cycle-level-faces nil
        org-ellipsis " …"))
