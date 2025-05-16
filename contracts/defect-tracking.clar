;; Defect Tracking Contract
;; Records identified issues and resolutions

(define-data-var admin principal tx-sender)

;; Data structure for defects
(define-map defects
  { defect-id: uint }
  {
    product-id: uint,
    reporter: principal,
    description: (string-ascii 500),
    severity: uint,  ;; 1-5 scale
    report-date: uint,
    resolved: bool,
    resolution: (optional (string-ascii 500)),
    resolution-date: (optional uint)
  }
)

;; Counter for defect IDs
(define-data-var defect-id-counter uint u0)

;; Report a new defect
(define-public (report-defect
    (product-id uint)
    (description (string-ascii 500))
    (severity uint))
  (let
    ((new-id (+ (var-get defect-id-counter) u1)))
    (begin
      (asserts! (<= severity u5) (err u400))
      (var-set defect-id-counter new-id)
      (map-set defects
        { defect-id: new-id }
        {
          product-id: product-id,
          reporter: tx-sender,
          description: description,
          severity: severity,
          report-date: block-height,
          resolved: false,
          resolution: none,
          resolution-date: none
        }
      )
      (ok new-id)
    )
  )
)

;; Resolve a defect
(define-public (resolve-defect
    (defect-id uint)
    (resolution (string-ascii 500)))
  (let
    ((defect (unwrap! (map-get? defects { defect-id: defect-id }) (err u404))))
    (begin
      (map-set defects
        { defect-id: defect-id }
        (merge defect {
          resolved: true,
          resolution: (some resolution),
          resolution-date: (some block-height)
        })
      )
      (ok true)
    )
  )
)

;; Get defect details
(define-read-only (get-defect (defect-id uint))
  (map-get? defects { defect-id: defect-id })
)

;; Check if a defect is resolved
(define-read-only (is-defect-resolved (defect-id uint))
  (default-to false (get resolved (map-get? defects { defect-id: defect-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
