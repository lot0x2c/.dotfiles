;;; tests/ui.el -*- lexical-binding: t; -*-

(defun toadtest-banner-margin ()
  "the left margin of the banner's first image."
  (with-current-buffer "*banner*"
    (let ((pos (point-min)) found)
      (while (and (not found) (setq pos (next-single-property-change pos 'display)))
        (let ((display (get-text-property pos 'display)))
          (when (eq (car-safe display) 'space)
            (setq found (car (plist-get (cdr display) :width))))))
      found)))

(defun toadtest-banner-image-width ()
  (with-current-buffer "*banner*"
    (let ((pos (point-min)) found)
      (while (and (not found) (setq pos (next-single-property-change pos 'display)))
        (let ((display (get-text-property pos 'display)))
          (when (eq (car-safe display) 'image)
            (setq found (car (image-size display t))))))
      found)))

(defun toadtest-banner-centered-p (window)
  (<= (abs (- (window-pixel-width window)
              (+ (* 2 (toadtest-banner-margin)) (toadtest-banner-image-width))))
      4))

(progn
  ;;; fonts and theme

  (check "doom-font" (equal (format "%s" (font-get doom-font :family)) "Monaspace Neon NF"))
  (check "doom-font size" (= (font-get doom-font :size) 16))
  (check "symbol font" (equal (format "%s" (font-get doom-symbol-font :family)) "Unifont"))
  (check "default face uses it" (string-match-p "Monaspace Neon" (face-attribute 'default :family)))
  (check "nerd icon font" (equal nerd-icons-font-family "Monaspace Neon NF"))
  (check "bubblegum on" (memq 'base16-bubblegum custom-enabled-themes))
  (check "region inverse" (face-attribute 'region :inverse-video))
  (check "gumball loads" (load-theme 'base16-gumball t t))
  (check "gumball not switched on" (not (memq 'base16-gumball custom-enabled-themes)))

  ;;; banner

  (redisplay t)
  (let ((window (get-buffer-window "*banner*")))
    (check "banner: both images"
           (with-current-buffer "*banner*"
             (let ((pos (point-min)) (n 0))
               (while (setq pos (next-single-property-change pos 'display))
                 (when (eq (car-safe (get-text-property pos 'display)) 'image)
                   (setq n (1+ n))))
               (= n 2))))
    (check "banner: centered after the frame settled" (toadtest-banner-centered-p window))
    (let ((new (with-selected-window window (split-window-right))))
      (redisplay t)
      (check "banner: centered again after a resize" (toadtest-banner-centered-p window))
      (delete-window new))
    (redisplay t)
    (check "banner: centered again at full size" (toadtest-banner-centered-p window)))

  ;;; no italics

  (with-current-buffer (get-buffer-create "*italic test*")
    (insert (propertize "slanted" 'face 'italic) " " (propertize "heavy" 'face 'bold-italic))
    (switch-to-buffer (current-buffer))
    (redisplay t)
    (let ((slanted (font-xlfd-name (font-at 1)))
          (heavy (font-xlfd-name (font-at 9))))
      (check "italic text draws upright" (not (string-match-p "-\\(?:italic\\|oblique\\)-" slanted)))
      (check "bold italic draws bold and upright"
             (and (string-match-p "-bold-" heavy)
                  (not (string-match-p "-\\(?:italic\\|oblique\\)-" heavy)))))
    (kill-buffer))

  ;;; modeline

  (find-file "~/org/agenda.org")
  (check "org-date not underlined" (null (face-attribute 'org-date :underline nil 'default)))
  (check "org-link underlined" (face-attribute 'org-link :underline))
  (let ((line (format-mode-line (doom-modeline-format--main))))
    (check "modeline: shows the workspace" (string-match-p "org" line))
    (check "modeline: shows the buffer" (string-match-p "agenda" line))
    (check "modeline: draws the cat"
           (let ((pos 0) found)
             (while (and (not found) pos (< pos (length line)))
               (when (eq (car-safe (get-text-property pos 'display line)) 'image)
                 (setq found t))
               (setq pos (next-single-property-change pos 'display line)))
             found)))
  (check "modeline: workspace name on" doom-modeline-persp-name)
  (check "nyan: animated" (and nyan-mode nyan-animate-nyancat (timerp nyan-animation-timer)))

  (check "no errors logged" (null (logged-errors))))

(let ((timer nyan-animation-timer))
  (load (expand-file-name "lisp/ui.el" doom-user-dir) nil t)
  (load (expand-file-name "lisp/ui.el" doom-user-dir) nil t)
  (check "UI reload keeps nyan enabled" nyan-mode)
  (check "UI reload reuses the animation timer" (eq timer nyan-animation-timer)))
