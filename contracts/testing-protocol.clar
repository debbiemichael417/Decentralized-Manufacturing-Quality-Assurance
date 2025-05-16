;; Testing Protocol Contract
;; Manages quality verification procedures

(define-data-var admin principal tx-sender)

;; Data structure for test protocols
(define-map test-protocols
  { protocol-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    required-steps: (list 10 (string-ascii 100)),
    created-by: principal,
    creation-date: uint
  }
)

;; Track test results for products
(define-map test-results
  { product-id: uint, protocol-id: uint }
  {
    tester: principal,
    passed: bool,
    test-date: uint,
    notes: (string-ascii 500)
  }
)

;; Counter for protocol IDs
(define-data-var protocol-id-counter uint u0)

;; Create a new test protocol
(define-public (create-protocol
    (name (string-ascii 100))
    (description (string-ascii 500))
    (required-steps (list 10 (string-ascii 100))))
  (let
    ((new-id (+ (var-get protocol-id-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (var-set protocol-id-counter new-id)
      (map-set test-protocols
        { protocol-id: new-id }
        {
          name: name,
          description: description,
          required-steps: required-steps,
          created-by: tx-sender,
          creation-date: block-height
        }
      )
      (ok new-id)
    )
  )
)

;; Record test results for a product
(define-public (record-test-result
    (product-id uint)
    (protocol-id uint)
    (passed bool)
    (notes (string-ascii 500)))
  (begin
    (asserts! (is-some (map-get? test-protocols { protocol-id: protocol-id })) (err u404))
    (map-set test-results
      { product-id: product-id, protocol-id: protocol-id }
      {
        tester: tx-sender,
        passed: passed,
        test-date: block-height,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Get protocol details
(define-read-only (get-protocol (protocol-id uint))
  (map-get? test-protocols { protocol-id: protocol-id })
)

;; Get test results for a product
(define-read-only (get-test-result (product-id uint) (protocol-id uint))
  (map-get? test-results { product-id: product-id, protocol-id: protocol-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
