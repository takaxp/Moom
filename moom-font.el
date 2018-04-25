;;; moom-font.el --- A module for resizing Japanese fonts for Moom

;; Copyright (C) 2017-2018 Takaaki ISHIKAWA

;; Author: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; Keywords: frames, faces, convenience
;; Version: 1.0.1
;; Maintainer: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; URL: https://github.com/takaxp/Moom
;; Twitter: @takaxp

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package is an additional module for Moom.el

;;; Change Log:

;;; Code:

(defcustom moom-font-ja "Osaka"
  "Font name for Japanese font."
  :type 'string
  :group 'moom)

(defcustom moom-font-ascii "Monaco"
  "Font name for ASCII font."
  :type 'string
  :group 'moom)

(defcustom moom-font-init-size 12
  "The default value to set font size."
  :type 'integer
  :group 'moom)

(defcustom moom-font-ja-scale 1.2
  "The default value to scale JP fonts."
  :type 'float
  :group 'moom)

(defcustom moom-font-ascii-scale 1.0
  "The default value to scale ASCII fonts."
  :type 'float
  :group 'moom)

(defcustom moom-font-verbose nil
  "Show responses from `moom`."
  :type 'boolean
  :group 'moom)

(defcustom moom-font-before-resize-hook nil
  "Hook runs before resizing font size."
  :type 'hook
  :group 'moom)

(defcustom moom-font-after-resize-hook nil
  "Hook runs after resizing font size."
  :type 'hook
  :group 'moom)

(defvar moom-font--size moom-font-init-size
  "Current font size.")

(defun moom-font--change-size (&optional arg)
  "Core function to change font size.
If `ARG' is nil, the default size is used."
  (when arg
    (setq moom-font--size arg))
  (let* ((font-size moom-font--size)
         (ja-font-scale moom-font-ja-scale)
         (ja-font moom-font-ja)
         (ja-rescale (concat ".*" ja-font ".*"))
         (ascii-font moom-font-ascii)
         (ascii-rescale (concat ".*" ascii-font ".*")))
    (setq face-font-rescale-alist
          `((,ja-rescale . ,moom-font-ja-scale)
            (,ascii-rescale . ,moom-font-ascii-scale)))
    (set-fontset-font nil 'ascii (font-spec :family ascii-font :size font-size))
    (let ((spec (font-spec :family ja-font :size font-size)))
      (set-fontset-font nil 'japanese-jisx0208 spec)
      (set-fontset-font nil 'katakana-jisx0201 spec)
      (set-fontset-font nil 'japanese-jisx0212 spec)
      (set-fontset-font nil '(#x0080 . #x024F) spec)
      (set-fontset-font nil '(#x0370 . #x03FF) spec)
      (set-fontset-font nil 'mule-unicode-0100-24ff spec))))

(defun moom-font--extract-font (xlfd)
  "Try to identify the font name.
Return a font name extracted from XLFD if possible, otherwise return nil."
  (when (stringp xlfd)
    (let* ((name (when (string-match "^-[^-]+-\\([^-]+\\)-.*$" xlfd)
                   (match-string 1 xlfd))))
      (if (and name (x-list-fonts name)) name nil))))

;;;###autoload
(defun moom-font-resize (&optional n width)
  "Resize font.
`frame-width' will be updated accordingly.
Optional argument N specifies the target font size.
If WIDTH is non-nil, ensure an appropriate font size so that
the actual pixel width will not exceed the WIDTH."
  (interactive "nSize: ")
  (run-hooks 'moom-font-before-resize-hook)
  (moom-font--change-size
   (setq moom-font--size (or n moom-font-init-size)))
  (when (and width
             (< width (frame-pixel-width)))
    (moom-font--change-size
     (setq moom-font--size (1- moom-font--size)))) ;; adjust frame-width
  (when moom-font-verbose
    (message "0: %s" moom-font--size))
  (run-hooks 'moom-font-after-resize-hook))

;;;###autoload
(defun moom-font-size-reset ()
  "Reset font to the initial size."
  (interactive)
  (run-hooks 'moom-font-before-resize-hook)
  (moom-font--change-size
   (setq moom-font--size moom-font-init-size))
  (when moom-font-verbose
    (message "0: %s" moom-font--size))
  (run-hooks 'moom-font-after-resize-hook))

;;;###autoload
(defun moom-font-increase (&optional inc)
  "Increase font size.
Optional argument INC specifies an increasing step."
  (interactive)
  (run-hooks 'moom-font-before-resize-hook)
  (setq moom-font--size
        (+ moom-font--size
           (if (and (integerp inc) (> inc 0))
               inc 1)))
  (moom-font--change-size moom-font--size)
  (when moom-font-verbose
    (message "+%d: %s" inc moom-font--size))
  (run-hooks 'moom-font-after-resize-hook))

;;;###autoload
(defun moom-font-decrease (&optional dec)
  "Decrease font size.
Optional argument DEC specifies a decreasing step."
  (interactive)
  (run-hooks 'moom-font-before-resize-hook)
  (setq moom-font--size
        (- moom-font--size
           (if (and (integerp dec)
                    (> dec 0)
                    (> moom-font--size dec))
               dec 1)))
  (when (and moom-font-verbose
             (> moom-font--size 0))
    (message "-%d: %s" dec moom-font--size))
  (moom-font--change-size moom-font--size)
  (run-hooks 'moom-font-after-resize-hook))

;;;###autoload
(defun moom-font-print-name-at-point ()
  "Print font name at point."
  (interactive)
  (if (eq (point) (point-max))
      (message "[moom-font] Not on a character. Move cursor, and try again.")
    (let* ((xlfd-name (font-xlfd-name (font-at (point))))
           (font (moom-font--extract-font xlfd-name)))
      (if font
          (message
           "[moom-font] Set \"%s\" to `moom-font-ja' or `moom-font-ascii.'"
           font)
        (message
         "[moom-font] Failed to detect the font name from \"%s\"."
         xlfd-name)))))

;; init
(when window-system
  (let ((font (moom-font--extract-font
               (cdr (assoc 'font (frame-parameters))))))
    (when font
      (setq moom-font-ascii font)
      (unless (eq system-type 'darwin)
        (setq moom-font-ja font))))) ;; TODO Refine this

(provide 'moom-font)

;;; moom-font.el ends here
