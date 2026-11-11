;;; lisp/org/bullets.el -*- lexical-binding: t; -*-

;; a heading's last star shows as + while everything under it is folded and - once any
;; of it is on screen, like the dired sidebar's folders. the leading stars stay hidden
;; as indentation, so a folded *** reads as two spaces and a +. a heading with nothing
;; under it shows -

(defconst ro15rend/org-bullet-category 'ro15rend-org-bullet)

(defun ro15rend/org-bullets--face (level)
  "the face org gives a LEVEL heading."
  (if org-cycle-level-faces
      (nth (% (1- level) org-n-level-faces) org-level-faces)
    (nth (1- (min level org-n-level-faces)) org-level-faces)))

(defun ro15rend/org-bullets--folded-p (from to)
  "whether FROM to TO has text and none of it is visible."
  (and (< from to)
       (let ((pos from))
         (while (and (< pos to) (invisible-p pos))
           (setq pos (next-single-char-property-change pos 'invisible nil to)))
         (>= pos to))))

(defun ro15rend/org-bullets--headings ()
  "each heading as (start level folded), in buffer order."
  (let (found open)
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        ;; a heading's body runs to the next heading at its level or above. blank lines
        ;; at its end stay on screen when it folds, so they don't count
        (cl-flet ((close (row next)
                    (let ((end (save-excursion (goto-char next)
                                               (skip-chars-backward " \t\n")
                                               (point))))
                      (setcar (nthcdr 2 row)
                              (ro15rend/org-bullets--folded-p (nth 2 row) end)))))
          (while (re-search-forward "^\\(\\*+\\) " nil t)
            (let* ((start (match-beginning 0))
                   (level (- (match-end 1) start))
                   ;; the third slot holds where the body starts until close fills it in
                   (row (list start level (min (point-max) (1+ (line-end-position))))))
              (while (and open (>= (nth 1 (car open)) level))
                (close (pop open) start))
              (push row open)
              (push row found)))
          (dolist (row open) (close row (point-max))))))
    (nreverse found)))

(defun ro15rend/org-bullets-refresh ()
  "set each heading's mark to match its fold state."
  (let ((existing (make-hash-table :test #'eql)))
    ;; index once: searching the overlay list per heading grows quadratically
    (dolist (overlay (overlays-in (point-min) (point-max)))
      (when (eq (overlay-get overlay 'category) ro15rend/org-bullet-category)
        (let ((start (overlay-start overlay)))
          (if (and (= (overlay-end overlay) (1+ start))
                   (not (gethash start existing)))
              (puthash start overlay existing)
            (delete-overlay overlay)))))
    (pcase-dolist (`(,start ,level ,folded) (ro15rend/org-bullets--headings))
      (let* ((star (+ start level -1))
             (mark (propertize (if folded "+" "-")
                               'face (ro15rend/org-bullets--face level)))
             (overlay (or (gethash star existing)
                          (make-overlay star (1+ star)))))
        (remhash star existing)
        (overlay-put overlay 'category ro15rend/org-bullet-category)
        (unless (equal-including-properties (overlay-get overlay 'display) mark)
          (overlay-put overlay 'display mark))))
    (maphash (lambda (_ overlay) (delete-overlay overlay)) existing)))

(defun ro15rend/org-bullets-setup-h ()
  "install fold markers in this org buffer."
  ;; the +/- mark already says whether a heading is folded, so no ellipsis
  (org-fold-core-set-folding-spec-property 'org-fold-outline :ellipsis nil)
  ;; folding doesn't touch the text, so check after every command
  (add-hook 'post-command-hook #'ro15rend/org-bullets-refresh nil t)
  (ro15rend/org-bullets-refresh))

(add-hook 'org-mode-hook #'ro15rend/org-bullets-setup-h)
