;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name    "ro15rend"
      user-mail-address "toadvnm@proton.me")

;; shared helpers and workspace roots come first, everything below uses them
(load! "lisp/lib")
(load! "lisp/places")

;; editing and presentation
(load! "lisp/editor")
(load! "lisp/windows")
(load! "lisp/ui")
(load! "lisp/banner/banner")

;; ghost-text completion: minuet, local, in org; copilot everywhere else
(load! "lisp/minuet")
(load! "lisp/copilot")

;; org paths precede the templates, inbox and commands that use them
(load! "lisp/org/files")
(load! "lisp/org/template")
(load! "lisp/org/inbox")
(load! "lisp/org/agenda")
(load! "lisp/org/review")
(load! "lisp/org/daily")
(load! "lisp/org/commands")
(load! "lisp/org/appearance")

;; file navigation and language integrations
(load! "lisp/dired")
(load! "lisp/pdf")
(load! "lisp/modes")
(load! "lisp/proverif")
(load! "lisp/pyret")
