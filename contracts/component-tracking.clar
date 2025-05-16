;; Component Tracking Contract
;; Records parts used in assembly

(define-data-var admin principal tx-sender)

;; Data structure for components
(define-map components
  { component-id: uint }
  {
    name: (string-ascii 100),
    manufacturer: principal,
    manufacturing-date: uint,
    batch-number: (string-ascii 50),
    specifications: (string-ascii 500)
  }
)

;; Track which components are used in which products
(define-map product-components
  { product-id: uint, component-id: uint }
  { used: bool }
)

;; Counter for component IDs
(define-data-var component-id-counter uint u0)

;; Register a new component
(define-public (register-component
    (name (string-ascii 100))
    (batch-number (string-ascii 50))
    (specifications (string-ascii 500)))
  (let
    ((new-id (+ (var-get component-id-counter) u1)))
    (begin
      (var-set component-id-counter new-id)
      (map-set components
        { component-id: new-id }
        {
          name: name,
          manufacturer: tx-sender,
          manufacturing-date: block-height,
          batch-number: batch-number,
          specifications: specifications
        }
      )
      (ok new-id)
    )
  )
)

;; Associate a component with a product
(define-public (add-component-to-product (product-id uint) (component-id uint))
  (begin
    (asserts! (is-some (map-get? components { component-id: component-id })) (err u404))
    (map-set product-components
      { product-id: product-id, component-id: component-id }
      { used: true }
    )
    (ok true)
  )
)

;; Get component details
(define-read-only (get-component (component-id uint))
  (map-get? components { component-id: component-id })
)

;; Check if a component is used in a product
(define-read-only (is-component-in-product (product-id uint) (component-id uint))
  (default-to
    { used: false }
    (map-get? product-components { product-id: product-id, component-id: component-id })
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
