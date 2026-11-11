;;; lisp/banner/banner.el -*- lexical-binding: t; -*-

(defconst ro15rend/banner-dir (dir!)
  "directory holding banner.txt and the pngs.")

(defconst ro15rend/banner-image-scale 0.28
  "image height as a fraction of window height, so it scales with the frame.")

(defun ro15rend/banner--art ()
  "the ascii art as lines."
  (with-temp-buffer
    (insert-file-contents (expand-file-name "banner.txt" ro15rend/banner-dir))
    (split-string (buffer-string) "\n" t)))

(defun ro15rend/banner--image (name height)
  "image NAME scaled to HEIGHT px, nil in a terminal."
  (when (display-graphic-p)
    (create-image (expand-file-name name ro15rend/banner-dir) nil nil :height height)))

(defun ro15rend/banner--insert-image (img win-pw)
  "insert IMG centered in a window WIN-PW pixels wide."
  (let ((margin (max 0 (/ (- win-pw (car (image-size img t))) 2))))
    (insert (propertize " " 'display `(space :width (,margin)))
            (propertize " " 'display img)
            "\n")))

(defun ro15rend/banner--pad (px)
  "insert PX pixels of vertical space."
  (when (> px 0)
    (let ((p (point)))
      (insert "\n")
      (put-text-property p (point) 'line-height px))))

(define-derived-mode ro15rend/banner-mode special-mode "Banner"
  "read-only buffer holding the banner. `q' buries it."
  (setq-local cursor-type nil
              mode-line-format nil
              display-line-numbers nil
              truncate-lines t)
  (buffer-disable-undo)
  ;; the window manager resizes the frame after this first draw
  (add-hook 'window-size-change-functions #'ro15rend/banner-redraw-h nil t))

(defun ro15rend/banner-render ()
  "draw the banner centered for the selected window, and return its buffer."
  (let* ((win     (selected-window))
         (win-pw  (window-pixel-width win))
         (win-ph  (window-pixel-height win))
         (img-h   (max 1 (round (* win-ph ro15rend/banner-image-scale))))
         (freedom (ro15rend/banner--image "freedom.png" img-h))
         (gnu     (ro15rend/banner--image "gnu.png" img-h))
         (lines   (ro15rend/banner--art))
         (art-w   (apply #'max (mapcar #'string-width lines)))
         (used    (+ (* (length lines) (frame-char-height (window-frame win)))
                     (if freedom img-h 0)
                     (if gnu img-h 0)))
         (v-pad   (max 0 (/ (- win-ph used) 2)))
         (h-pad   (max 0 (/ (- (window-body-width win) art-w) 2)))
         (buf     (get-buffer-create "*banner*")))
    (with-current-buffer buf
      (unless (derived-mode-p 'ro15rend/banner-mode) (ro15rend/banner-mode))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ro15rend/banner--pad v-pad)
        (when freedom (ro15rend/banner--insert-image freedom win-pw))
        (dolist (line lines)
          (insert (make-string h-pad ?\s) line "\n"))
        (when gnu (ro15rend/banner--insert-image gnu win-pw))
        (ro15rend/banner--pad v-pad))
      (goto-char (point-min)))
    buf))

(defun ro15rend/banner-redraw-h (window)
  "draw the banner again for WINDOW's new size."
  (with-selected-window window
    (ro15rend/banner-render)))

(setq initial-buffer-choice #'ro15rend/banner-render)
