;;; -*- lexical-binding: t; -*-
;;; etaf-solitaire-tests.el --- Public application behavior
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'ert)
(require 'etaf-solitaire)

(defun etaf-solitaire-test--wait (session &optional predicate)
  "Await SESSION's painted board and optional PREDICATE."
  (let ((end (+ (float-time) 6)))
    (while (and (< (float-time) end)
                (not (memq (etaf-gamekit-status session) '(failed closed)))
                (or (not (eq (etaf-gamekit-status session) 'ready))
                    (not (etaf-host-ref-size (etaf-runtime-for-buffer (etaf-gamekit-buffer session)) 'solitaire-board))
                    (and predicate (not (funcall predicate)))))
      (accept-process-output nil 0.01)))
  (should (eq (etaf-gamekit-status session) 'ready))
  (should-not (etaf-gamekit-last-error session))
  (when predicate (should (funcall predicate))))

(defun etaf-solitaire-test--close (session)
  "Dispose the application INSTANCE and its buffer."
  (when session (etaf-solitaire-close session)))

(defun etaf-solitaire-test--key (key)
  "Run the native command bound to KEY in the application buffer."
  (let ((command (key-binding (kbd key))))
    (should (commandp command))
    (call-interactively command)))

(ert-deftest etaf-solitaire-card-input-moves-native-cards-and-restores-history ()
  "Selecting a card and its foundation changes native state; undo/redo restore it."
  (let ((session (etaf-gamekit-start etaf-solitaire-game :options '(:seed 11))))
    (unwind-protect
        (let ((runtime (etaf-runtime-for-buffer (etaf-gamekit-buffer session))))
          (etaf-runtime-refit runtime 1100 44)
          (etaf-solitaire-test--wait session)
          (let ((before (etaf-gamekit-view session :observation)))
            (etaf-dispatch-event runtime 'solitaire-card-A♣ 'press)
            (etaf-dispatch-event runtime 'solitaire-foundation-2 'press)
            (etaf-solitaire-test--wait session (lambda () (= (etaf-gamekit-view session :action_count) 1)))
            (let ((after (etaf-gamekit-view session :observation)))
              (should-not (equal before after))
              (etaf-dispatch-event runtime 'solitaire-undo 'press)
              (etaf-solitaire-test--wait session (lambda () (= (etaf-gamekit-view session :action_count) 0)))
              (should (equal before (etaf-gamekit-view session :observation)))
              (etaf-dispatch-event runtime 'solitaire-redo 'press)
              (etaf-solitaire-test--wait session (lambda () (= (etaf-gamekit-view session :action_count) 1)))
              (should (equal after (etaf-gamekit-view session :observation))))))
      (etaf-solitaire-test--close session))))

(ert-deftest etaf-solitaire-themes-and-resize-preserve-the-deal ()
  "Light/dark switching and narrow layouts preserve state, selection and card metrics."
  (let* ((etaf-solitaire-appearance 'light)
         (session (etaf-gamekit-start etaf-solitaire-game :options '(:seed 11))))
    (unwind-protect
        (let ((runtime (etaf-runtime-for-buffer (etaf-gamekit-buffer session))))
          (etaf-runtime-refit runtime 1100 44)
          (etaf-solitaire-test--wait session)
          (etaf-dispatch-event runtime 'solitaire-card-A♣ 'press)
          (let ((before (etaf-gamekit-observation session))
                (card (etaf-host-ref-size runtime 'solitaire-card-A♣)))
            (dotimes (_ 2)
              (etaf-dispatch-event runtime 'solitaire-theme 'press)
              (should (equal before (etaf-gamekit-observation session)))
              (should (equal card (etaf-host-ref-size runtime 'solitaire-card-A♣))))
            (dolist (rows '(70 44 30))
              (etaf-runtime-refit runtime 1100 rows)
              (let* ((size (etaf-host-ref-size runtime 'solitaire-root))
                     (bounds (etaf-host-ref-bounds runtime 'solitaire-root))
                     (surplus (max 0 (- rows (cdr size))))
                     (top (with-current-buffer (etaf-gamekit-buffer session)
                            (1- (line-number-at-pos (car bounds))))))
                (should (<= (abs (- top (* 0.4 surplus))) 1)))
              (let ((current-card (etaf-host-ref-size runtime 'solitaire-card-A♣)))
                (should (equal card current-card))))
            (etaf-runtime-refit runtime 90 32)
            (should (equal card (etaf-host-ref-size runtime 'solitaire-card-A♣)))
            (should (equal before (etaf-gamekit-observation session)))
            (etaf-dispatch-event runtime 'solitaire-foundation-2 'press)
            (etaf-solitaire-test--wait session (lambda () (= (etaf-gamekit-view session :action_count) 1)))))
      (etaf-solitaire-test--close session))))

(ert-deftest etaf-solitaire-escape-dismisses-the-selection ()
  "Framework Escape clears a picked card so a later target press is inert."
  (let ((session (etaf-gamekit-start etaf-solitaire-game :options '(:seed 11))))
    (unwind-protect
        (let ((runtime (etaf-runtime-for-buffer (etaf-gamekit-buffer session))))
          (etaf-runtime-refit runtime 1100 44)
          (etaf-solitaire-test--wait session)
          (etaf-dispatch-event runtime 'solitaire-card-A♣ 'press)
          (with-current-buffer (etaf-gamekit-buffer session)
            (etaf-solitaire-test--key "<escape>"))
          (should-error (etaf-dispatch-event runtime 'solitaire-foundation-2 'press)
                        :type 'etaf-event-error)
          (should (= (etaf-gamekit-view session :action_count) 0)))
      (etaf-solitaire-test--close session))))

(provide 'etaf-solitaire-tests)
;;; etaf-solitaire-tests.el ends here
