#!/usr/bin/env -S racket -f

(define (parse-line line)
  (read (open-input-string (string-replace line "," " "))))

(define (read-exprs file)
  (let ((line (read-line file)))
    (if (eof-object? line)
        '()
        (cons (parse-line line) (read-exprs file)))))

;; Search for the first expression that can be exploded (nested pair > 4 levels
;; deep) and mark it by converting the pair to #t and returning the pair separately.
(define (explode-find pair [depth 0])
  (if (list? pair)
      (if (and (>= depth 4) (and (not (list? (first pair))) (not (list? (second pair)))))
          ;; this pair can be exploded
          (list #t pair)
          ;; try left side before trying right
          (let ((res (explode-find (first pair) (+ depth 1))))
            (if (cadr res)
                ;; left side exploded, so return immediately
                (list (list (car res) (second pair)) (cadr res))
                (let ((res2 (explode-find (second pair) (+ depth 1))))
                  (if (cadr res2)
                      (list (list (first pair) (car res2)) (cadr res2))
                      (list pair #f))))
            ))
      ;; if not a list, just return the number
      (list pair #f)))

;; Flatten the result of explode-find into a list
(define (explode-flatten pair)
  (if (list? pair)
      (flatten (list (list "(")
                     (explode-flatten (first pair))
                     (explode-flatten (second pair))
                     (list ")")))
      (list pair)))

;; Adds n to the first number after #t in nums
(define (add-first-number nums n [passed #f])
  (cond
    ;; didn't find it
    [(null? nums) nums]
    [(and passed (number? (first nums)))
     ;; we found the first number, so add n to it and finish recursion
     (cons (+ (first nums) n) (rest nums))]
    [(and (not passed) (eq? (first nums) #t))
     ;; we found the #t, so begin looking for the first number
     (cons (first nums) (add-first-number (rest nums) n #t))]
    [else
     ;; keep looking
     (cons (first nums) (add-first-number (rest nums) n passed))]
    ))

;; Adds the value of right to the first number to the right of #t and left to
;; the first number to the left of #t and replaces the #t with 0
(define (explode-update vals left right)
  (let* ([added-right (add-first-number vals right)]
         [reversed (reverse added-right)]
         [added-left (add-first-number reversed left)]
         [reversed-again (reverse added-left)]
         [replaced-with-zero (map (lambda (x) (if (eq? x #t) 0 x)) reversed-again)])
    replaced-with-zero))

;; Converts a list of numbers and string back into an S-expression
(define (explode-unflatten vals)
  (let* ([number-to-string (lambda (x) (if (number? x) (number->string x) x))]
         [strings (map number-to-string vals)]
         [str (string-join strings " ")])
    (read (open-input-string str))))

;; Tries to explode a pair, returning the result and success
(define (explode pair)
  (let ([found (explode-find pair)])
    (if (second found)
        (let* ([pair (first found)]
               [left (first (second found))]
               [right (second (second found))]
               [vals (explode-flatten pair)]
               [updated (explode-update vals left right)]
               [unflattened (explode-unflatten updated)])
          (list unflattened #t))
        (list pair #f))))

;; Tries to split a number x into two parts, floor(x/2) and ceil(x/2), if they
;; are >= 10. Returns the result and success. Stops immediately after a split occurs.
(define (split pair)
  (if (number? pair)
      (if (>= pair 10)
          ;; split the number
          (let ([left (floor (/ pair 2))]
                [right (ceiling (/ pair 2))])
            (list (list left right) #t))
          ;; < 10, so just return the number
          (list pair #f))
      ;; try splitting left first before splitting right
      (let ([left-split-res (split (first pair))])
        (if (second left-split-res)
            (list (list (first left-split-res) (second pair)) #t)
            (let ([right-split-res (split (second pair))])
              (if (second right-split-res)
                  (list (list (first pair) (first right-split-res)) #t)
                  (list pair #f)))))))

;; Reduce a "snailfish number" by applying explodes and splits as long as
;; possible. Explodes are preferred over splits.
(define (snailfish-reduce pair)
    (let ([try-explode (explode pair)])
      (if (second try-explode)
          ;; keep trying to explode as long as possible
          (snailfish-reduce (first try-explode))
          ;; try splitting
          (let ([try-split (split pair)])
            (if (second try-split)
                ;; keep trying to reduce as long as possible
                (snailfish-reduce (first try-split))
                ;; no more splits, so return the pair
                pair)))))

(define (snailfish-add left right)
  (snailfish-reduce (list left right)))

(define (snailfish-sum nums)
  (foldl (lambda (x y) (snailfish-add y x)) (first nums) (rest nums)))

(define (snailfish-magnitude pair)
  (if (number? pair)
      pair
      (+ (* 3 (snailfish-magnitude (first pair)))
         (* 2 (snailfish-magnitude (second pair))))))

(require racket/trace)

;; (trace explode)
;; (trace split)
;; (trace explode-update)

;; (displayln (explode '[[3 [2 [1 [7 3]]]] [6 [5 [4 [3 2]]]]]))
;; (displayln (split '(1 (12 5))))

;; (displayln (snailfish-add
;;             (parse-line "[[[[4,3],4],4],[7,[[8,4],9]]]")
;;             (parse-line "[1,1]]")
;;             ))

(call-with-input-file "input.txt"
  (lambda (in)
    ;; (displayln (snailfish-magnitude (snailfish-sum (read-exprs in))))
    (let ([nums (read-exprs in)])
      (displayln (apply max (for*/list ([x nums] [y nums])
                              (snailfish-magnitude (snailfish-add x y))))))))
