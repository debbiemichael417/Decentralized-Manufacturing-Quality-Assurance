;; Certification Contract
;; Validates finished product quality

(define-data-var admin principal tx-sender)

;; Data structure for certifications
(define-map certifications
  { product-id: uint }
  {
    certifier: principal,
    certification-date: uint,
    expiration-date: (optional uint),
    quality-score: uint,  ;; 0-100 scale
    notes: (string-ascii 500),
    revoked: bool
  }
)

;; Certify a product
(define-public (certify-product
    (product-id uint)
    (quality-score uint)
    (notes (string-ascii 500))
    (expiration-date (optional uint)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= quality-score u100) (err u400))
    (map-set certifications
      { product-id: product-id }
      {
        certifier: tx-sender,
        certification-date: block-height,
        expiration-date: expiration-date,
        quality-score: quality-score,
        notes: notes,
        revoked: false
      }
    )
    (ok true)
  )
)

;; Revoke a certification
(define-public (revoke-certification (product-id uint))
  (let
    ((cert (unwrap! (map-get? certifications { product-id: product-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set certifications
        { product-id: product-id }
        (merge cert { revoked: true })
      )
      (ok true)
    )
  )
)

;; Get certification details
(define-read-only (get-certification (product-id uint))
  (map-get? certifications { product-id: product-id })
)

;; Check if a product is certified
(define-read-only (is-product-certified (product-id uint))
  (let
    ((cert (map-get? certifications { product-id: product-id })))
    (and
      (is-some cert)
      (not (get revoked (default-to
        { revoked: true }
        cert
      )))
    )
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
