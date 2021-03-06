(setq prelude-minimalistic-ui t)
(scroll-bar-mode -1)
(setq prelude-whitespace nil)
(setq mouse-wheel-progressive-speed nil)
(setq prelude-theme nil)
(setq prelude-flyspell nil)

;; Don't be so quick
(setq confirm-kill-emacs 'y-or-n-p)
(if (display-graphic-p)
    (put 'suspend-frame 'disabled t))

;; Dired: default program to use when using "&" on a file.
(setq dired-guess-shell-alist-user '(("\\.pdf\\'" "zathura")))

(setq fill-column 80)

;; AUCTeX preview font size
(set-default 'preview-scale-function 1.3)
(global-hl-line-mode -1)
(setq global-hl-line-mode -1)

(add-hook 'prelude-mode-hook
	  (lambda ()
	    (define-key prelude-mode-map (kbd "C-a") 'move-beginning-of-line)
            (define-key prelude-mode-map (kbd "M-o") 'ace-window)))

(global-set-key (kbd "<f5>") 'revert-buffer)
(global-set-key (kbd "C-c c") 'counsel-compile)
(global-set-key (kbd "C-c j") 'counsel-rg)
(global-set-key (kbd "C-c '") 'avy-goto-char-2)
(global-set-key (kbd "C-c ;") 'avy-goto-char-in-line)
