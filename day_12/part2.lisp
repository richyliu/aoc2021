#!/usr/bin/env -S sbcl --script

(require 'uiop)

;; read input.txt a list of adjacent nodes
(defun read-input (file)
  (uiop:read-file-lines file))

;; convert list of adjacent nodes to adjacency list
(defun convert-to-adjacency-list (input)
  (let ((alist (make-hash-table :test 'equal)))
    (dolist (node-pair input alist)
      (let* ((nodes (uiop:split-string node-pair :separator "-"))
            (node1 (car nodes))
            (node2 (cadr nodes)))
        (progn
          (push node2 (gethash node1 alist))
          (push node1 (gethash node2 alist)))))))



;; checks if a string is all uppercase
(defun all-caps? (str)
  (equal (string-upcase str) str))

;; Count the number of paths starting from start to "end" that don't pass
;; visited (unless it's an uppercase node, which can be visited multiple times).
;; We can visit a single lowercase node twice.
(defun count-paths-from (alist start visited used-twice)
  (if (equal start "end")
      1
      (let ((count 0))
        ;; for all neighbors of node
        (dolist (node (gethash start alist) count)
          (cond
            ;; we can always visit an uppercase node
            ((all-caps? node)
              (setq count (+ count (count-paths-from alist node (cons node visited) used-twice))))
            ;; visit a lowercase node twice unless it's "start"
            ((and (member node visited :test 'equal) (not used-twice) (not (equal node "start")))
              (setq count (+ count (count-paths-from alist node (cons node visited) t))))
            ;; visit a lowercase node once if we haven't visited it yet
            ((not (member node visited :test 'equal))
              (setq count (+ count (count-paths-from alist node (cons node visited) used-twice)))))))))

;; counts the number of distinct paths from start to end that pass lowercase
;; nodes at most once
(defun count-paths (alist)
  (count-paths-from alist "start" '("start") nil))

(print (count-paths (convert-to-adjacency-list (read-input "input.txt"))))
