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

;; count the number of paths starting from start to "end" that don't pass
;; visited (unless it's an uppercase node, which can be visited multiple times)
(defun count-paths-from (alist start visited)
  (if (equal start "end")
      1
      (let ((count 0))
        ;; for all neighbors of node
        (dolist (node (gethash start alist) count)
          ;; if we can visit this neighbor
          (if (or (all-caps? node) (not (member node visited :test 'equal)))
              (setq count (+ count (count-paths-from alist node (cons node visited)))))))))

;; counts the number of distinct paths from start to end that pass lowercase
;; nodes at most once
(defun count-paths (alist)
  (count-paths-from alist "start" '("start")))

(print (count-paths (convert-to-adjacency-list (read-input "input.txt"))))
