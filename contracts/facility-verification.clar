;; Facility Verification Contract
;; Validates production sites and their capabilities

(define-data-var admin principal tx-sender)

;; Data structure for facilities
(define-map facilities
  { facility-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    capabilities: (string-ascii 500),
    verified: bool,
    verification-date: uint
  }
)

;; Counter for facility IDs
(define-data-var facility-id-counter uint u0)

;; Register a new facility
(define-public (register-facility (name (string-ascii 100)) (location (string-ascii 100)) (capabilities (string-ascii 500)))
  (let
    ((new-id (+ (var-get facility-id-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (var-set facility-id-counter new-id)
      (map-set facilities
        { facility-id: new-id }
        {
          owner: tx-sender,
          name: name,
          location: location,
          capabilities: capabilities,
          verified: false,
          verification-date: u0
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a facility
(define-public (verify-facility (facility-id uint))
  (let
    ((facility (unwrap! (map-get? facilities { facility-id: facility-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set facilities
        { facility-id: facility-id }
        (merge facility {
          verified: true,
          verification-date: block-height
        })
      )
      (ok true)
    )
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id })
)

;; Check if a facility is verified
(define-read-only (is-facility-verified (facility-id uint))
  (default-to false (get verified (map-get? facilities { facility-id: facility-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
