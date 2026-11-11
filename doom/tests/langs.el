;;; tests/langs.el -*- lexical-binding: t; -*-

;; open real code in every language: right mode, colors, no prompts. language servers aren't started.

(defconst toadtest-code
  '(("t.c" c-ts-mode "int main(void) {\n  return 0;\n}\n")
    ("t.cpp" c++-ts-mode "int main() {\n  return 0;\n}\n")
    ("t.py" python-ts-mode "def f(x):\n    return x\n")
    ("t.js" js-ts-mode "const a = 1;\nfunction f(x) { return x; }\n")
    ("t.jsx" tsx-ts-mode "const a = <div>hi</div>;\nexport default a;\n")
    ("t.ts" typescript-ts-mode "const a: number = 1;\nexport function f(x: string) { return x; }\n")
    ("t.tsx" tsx-ts-mode "const a = <div>hi</div>;\nexport default a;\n")
    ("t.lua" lua-ts-mode "local a = 1\nfunction f(x) return x end\n")))

(defun toadtest-typed (start keys)
  "the buffer after typing KEYS in insert state at the end of START."
  (erase-buffer)
  (insert start)
  (goto-char (point-max))
  (evil-insert-state)
  (execute-kbd-macro (kbd keys))
  (evil-normal-state)
  (buffer-substring-no-properties (point-min) (point-max)))

(let ((prompts nil))
  (advice-add 'lsp! :override #'ignore)
  (cl-letf (((symbol-function 'y-or-n-p)
             (lambda (prompt &rest _) (push (substring-no-properties prompt) prompts) nil)))

    ;;; tree-sitter languages

    (require 'treesit)
    (dolist (lang '(c cpp python javascript jsdoc typescript tsx lua))
      (check (format "grammar installed: %s" lang) (treesit-language-available-p lang)))
    (dolist (spec toadtest-code)
      (spit (concat "~/code/" (nth 0 spec)) (nth 2 spec))
      (setq prompts nil)
      (find-file (concat "~/code/" (nth 0 spec)))
      (check (format "%s: %s" (nth 0 spec) (nth 1 spec)) (eq major-mode (nth 1 spec)))
      (check (format "%s: has colors" (nth 0 spec)) (> (faced-chars) 0))
      (check (format "%s: no install prompt" (nth 0 spec)) (null prompts))
      (drop (concat "~/code/" (nth 0 spec))))

    ;;; other modes

    (dolist (spec '(("t.fish" fish-mode "set x 1\n") ("t.yaml" yaml-mode "a: 1\n")
                    ("t.nix" nix-mode "{ a = 1; }\n") ("t.sh" sh-mode "echo hi\n")
                    ("t.html" web-mode "<p>x</p>\n") ("t.svelte" web-mode "<p>x</p>\n")
                    ("t.css" css-mode "a { color: red; }\n") ("t.tex" LaTeX-mode "\\section{a}\n")
                    ("t.md" markdown-mode "# a\n") ("t.el" emacs-lisp-mode "(setq a 1)\n")
                    ("t.hs" haskell-mode "main :: IO ()\nmain = putStrLn \"hi\"\n")))
      (spit (concat "~/code/" (nth 0 spec)) (nth 2 spec))
      (find-file (concat "~/code/" (nth 0 spec)))
      (check (format "%s: %s" (nth 0 spec) (nth 1 spec)) (eq major-mode (nth 1 spec)))
      (check (format "%s: has colors" (nth 0 spec)) (> (faced-chars) 0))
      (when (eq major-mode 'haskell-mode)
        (check "t.hs: language server hooked" (memq 'lsp! haskell-mode-local-vars-hook)))
      (drop (concat "~/code/" (nth 0 spec))))

    ;;; formatters

    (require 'apheleia)
    (dolist (spec '((python-mode . ruff) (python-ts-mode . ruff) (sh-mode . shfmt)
                    (haskell-mode . fourmolu)
                    (nix-mode . nixfmt) (c-ts-mode . clang-format)
                    (typescript-ts-mode . prettier-typescript) (js-ts-mode . prettier-javascript)
                    (web-mode . prettier) (css-mode . prettier-css)))
      (check (format "format: %s uses %s" (car spec) (cdr spec))
             (let ((set (alist-get (car spec) apheleia-mode-alist)))
               (or (eq set (cdr spec)) (memq (cdr spec) (ensure-list set))))))

    ;;; proverif

    (spit "~/code/good.pv" "free c: channel.\nprocess\n  out(c, c)\n")
    (spit "~/code/bad.pv" "free c: channel.\nprocess\n  out(c, undefined_name)\n")
    (dolist (spec '(("good" . 0) ("bad" . 1)))
      (find-file (format "~/code/%s.pv" (car spec)))
      (check (format "%s.pv: mode" (car spec)) (eq major-mode 'proverif-pv-mode))
      (check (format "%s.pv: flycheck on" (car spec)) (bound-and-true-p flycheck-mode))
      (check (format "%s.pv: checker" (car spec)) (eq (flycheck-get-checker-for-buffer) 'proverif))
      (flycheck-buffer)
      (let ((i 0))
        (while (and (flycheck-running-p) (< i 200))
          (accept-process-output nil 0.1)
          (setq i (1+ i))))
      (check (format "%s.pv: %d errors" (car spec) (cdr spec))
             (= (length flycheck-current-errors) (cdr spec))))

    ;;; pyret

    (spit "~/code/t.arr" "fun f():\n  1\nend\n")
    (find-file "~/code/t.arr")
    (check "pyret: mode" (eq major-mode 'pyret-mode))
    (check "pyret: counts as code" (derived-mode-p 'prog-mode))
    (check "pyret: colors" (> (faced-chars) 0))
    (check "pyret: line numbers" display-line-numbers)
    (check "pyret: undo-tree" (bound-and-true-p undo-tree-mode))
    (check "pyret: smartparens" (bound-and-true-p smartparens-mode))
    (check "pyret: flycheck" (bound-and-true-p flycheck-mode))
    (dolist (spec '(("end dedents" "fun f():\n  1\n  " "e n d" "fun f():\n  1\nend")
                    ("no expanding to a longer word" "ending = 1\nfun f():\n  1\n  " "e n d"
                     "ending = 1\nfun f():\n  1\nend")
                    ("a whole function" "" "f u n SPC g ( x ) : RET x SPC + SPC 1 RET e n d RET"
                     "fun g(x):\n  x + 1\nend\n")
                    ("else dedents" "if a:\n  1\n  " "e l s e : RET 2 RET e n d"
                     "if a:\n  1\nelse:\n  2\nend")
                    ("data bars line up" "data T:\n  " "| SPC a RET | SPC b RET e n d"
                     "data T:\n  | a\n  | b\nend")
                    ("words containing end" "x = 1\n" "s e n d e r" "x = 1\nsender")
                    ("words ending in end" "x = 1\n" "f r i e n d" "x = 1\nfriend")
                    ("end in a string" "x = \"" "e n d" "x = \"end")
                    ("operators" "x = 1\n" "y SPC = SPC 2 SPC + SPC 3 SPC - SPC 4" "x = 1\ny = 2 + 3 - 4")
                    ("tab re-indents" "fun f():\n1" "<tab>" "fun f():\n  1")))
      (check (format "pyret typing: %s" (nth 0 spec))
             (equal (toadtest-typed (nth 1 spec) (nth 2 spec)) (nth 3 spec))))
    (erase-buffer)
    (insert "fun f(x):\nx + 1\nend\ndata T:\n| a\n| b\nend\nif true:\n1\nelse:\n2\nend\ncheck:\nf(1) is 2\nend\n")
    (indent-region (point-min) (point-max))
    (check "pyret: indent-region"
           (equal (buffer-substring-no-properties (point-min) (point-max))
                  "fun f(x):\n  x + 1\nend\ndata T:\n  | a\n  | b\nend\nif true:\n  1\nelse:\n  2\nend\ncheck:\n  f(1) is 2\nend\n"))
    (set-buffer-modified-p nil))
  (advice-remove 'lsp! #'ignore)
  (check "no errors logged" (null (logged-errors))))
