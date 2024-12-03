(defun display-startup-time ()
  (message
   "Emacs loaded in %s with %d garbage collections."
   (format
    "%.2f seconds"
    (float-time
     (time-subtract after-init-time before-init-time)))
   gcs-done))

(add-hook 'emacs-startup-hook #'display-startup-time)

(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (toggle-frame-maximized))

(menu-bar-mode -1)

(fset 'yes-or-no-p 'y-or-n-p)

(setq
 global-auto-revert-non-file-buffers t
 auto-revert-verbose nil
 show-paren-style 'mixed
 visible-bell t
 backup-inhibited t
 auto-save-default nil
 inhibit-startup-message t
 inhibit-startup-echo-area-message t
 mouse-wheel-follow-mouse t
 ns-pop-up-frames nil
 display-time-24hr-format t
 display-time-default-load-average nil
 tab-always-indent 'complete
 standard-indent 2
 save-abbrevs nil
 savehist-additional-variables
 '(kill-ring
   mark-ring
   global-mark-ring
   search-ring
   regexp-search-ring
   extended-command-history)
 echo-keystrokes 0.1
 confirm-nonexistent-file-or-buffer nil
 confirm-kill-emacs 'y-or-n-p
 ring-bell-function 'ignore
 user-mail-address "n.oje.bar@gmail.com"
 user-full-name  "Nicolás Ojeda Bär"
 uniquify-buffer-name-style 'forward
 help-window-select t
 send-mail-function 'smtpmail-send-it
 smtpmail-smtp-server "smtp.gmail.com"
 smtpmail-smtp-service 465
 smtpmail-stream-type 'ssl
 c-old-style-variable-behavior t
 epa-pinentry-mode 'loopback
 ;; vc-git-print-log-follow t
 vc-find-revision-no-save t
 project-vc-merge-submodules nil
 vc-include-untracked nil
 completion-auto-help 'visible
 completion-auto-select 'second-tab
 groovy-indent-offset 2)

(setq custom-file (concat temporary-file-directory "emacs-custom"))

(setq-default
 require-final-newline 'ask
 fill-column 80
 indent-tabs-mode nil
 css-indent-offset 2
 js-indent-level 2
 c-basic-offset 2
 ediff-forward-word-function 'forward-char
 whitespace-line-column 80
 whitespace-style '(face trailing lines-tail tabs))

(global-auto-revert-mode 1)
(display-time-mode)
(column-number-mode 1)
(size-indication-mode 1)
(delete-selection-mode 1)
(global-font-lock-mode 1)
(show-paren-mode 1)
(savehist-mode 1)
(winner-mode 1)
;; (global-whitespace-mode 1)
;; (repeat-mode)

(defun ask-to-delete-trailing-whitespace ()
  (let ((buffer-size-after-deleting-trailing-whitespace
         (let ((curr (current-buffer)))
           (with-temp-buffer
             (insert-buffer curr)
             (delete-trailing-whitespace)
             (buffer-size)))))
    (if (and
         (not (= buffer-size-after-deleting-trailing-whitespace
                 (buffer-size)))
         (yes-or-no-p "Trailing whitespace: do you want to delete it?"))
        (delete-trailing-whitespace))))

(add-hook 'before-save-hook 'ask-to-delete-trailing-whitespace)
(add-hook 'c-mode-hook (lambda () (c-set-offset 'case-label '+)))

(global-set-key (kbd "<C-kp-add>") 'text-scale-increase)
(global-set-key (kbd "<C-kp-subtract>") 'text-scale-decrease)
(global-set-key (kbd "<C-kp-0>") 'text-scale-mode)

(require 'saveplace)

(if (< emacs-major-version 25)
    (setq-default save-place t)
  (save-place-mode 1))

(setq save-place-forget-unreadable-files nil)

(require 'dired-x)
(require 'package)
(require 'vc-git)

(let ((font "Consolas"))
  (when (and window-system (member font (font-family-list)))
    (set-face-attribute 'default nil :font font)))

(load-theme 'doom-one t)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(if (getenv "OPAM_SWITCH_PREFIX")
    (let ((opam-share (ignore-errors (car (process-lines "opam" "var" "share")))))
      (when (and opam-share (file-directory-p opam-share))
        (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share))))
  (when (setq ocamlc-command (executable-find "ocamlc"))
    (setq ocamlc-command (file-chase-links ocamlc-command))
    (setq merlin-command (executable-find "ocamlmerlin"))
    (let ((site-lisp
           (concat (file-name-directory (directory-file-name (file-name-directory ocamlc-command))) "share/emacs/site-lisp")))
      (when (file-exists-p site-lisp)
        (add-to-list 'load-path site-lisp)))))

;; (add-hook 'caml-mode-hook 'eglot-ensure t)

(setq merlin-error-on-single-line t)

(with-eval-after-load 'merlin
  (define-key merlin-mode-map (kbd "M-n") 'merlin-error-next)
  (define-key merlin-mode-map (kbd "M-p") 'merlin-error-prev))

(with-eval-after-load 'flymake
  (define-key flymake-mode-map (kbd "M-n") 'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "M-p") 'flymake-goto-prev-error))

(when (eq system-type 'windows-nt)
  (setq inhibit-compacting-font-caches t
        shell-file-name (executable-find "bash.exe")
        tramp-default-method "sshx"))

(when (require 'ocamlformat nil t)
  (add-hook 'before-save-hook 'ocamlformat-before-save))

(when (and (require 'merlin nil t) (executable-find "ocamlmerlin"))
  (add-hook 'caml-mode-hook 'merlin-mode t))

(defun set-caml-compile-command ()
  (set (make-local-variable 'compile-command)
       (format "dune build '%%{cmx:%s}'"
               (file-name-sans-extension  (file-name-nondirectory buffer-file-name)))))

(when (locate-library "caml")
  (autoload 'caml-mode "caml" nil t nil)
  (add-to-list 'auto-mode-alist '("\\.ml[iylp]?$" . caml-mode)))

(with-eval-after-load "caml"
  (require 'ocp-indent nil t)
  (require 'caml-font nil t)
  (add-hook 'caml-mode-hook 'set-caml-compile-command))

(setq package-check-signature nil)

(setq split-height-threshold nil)

;; (setq custom-safe-themes t)

;; (global-set-key (kbd "C-x g") 'vc-git-grep)

;; (recentf-mode)
(which-key-mode)

(windmove-default-keybindings '(meta))

(setq completion-auto-help 'visible
      completion-auto-select 'second-tab)

(global-set-key (kbd "C-x p C") 'recompile)
