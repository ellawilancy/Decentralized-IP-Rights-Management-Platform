;; Licensing and Usage Rights Contract

(define-map licenses
  { license-id: uint }
  {
    asset-id: uint,
    licensee: principal,
    licensor: principal,
    start-date: uint,
    end-date: uint,
    terms: (string-utf8 1000),
    status: (string-ascii 20)
  }
)

(define-map asset-licenses
  { asset-id: uint }
  { license-ids: (list 100 uint) }
)

(define-data-var license-id-nonce uint u0)

(define-public (create-license
  (asset-id uint)
  (licensee principal)
  (end-date uint)
  (terms (string-utf8 1000))
)
  (let
    ((new-license-id (+ (var-get license-id-nonce) u1))
     (current-licenses (default-to { license-ids: (list) } (map-get? asset-licenses { asset-id: asset-id }))))
    (map-set licenses
      { license-id: new-license-id }
      {
        asset-id: asset-id,
        licensee: licensee,
        licensor: tx-sender,
        start-date: block-height,
        end-date: end-date,
        terms: terms,
        status: "active"
      }
    )
    (map-set asset-licenses
      { asset-id: asset-id }
      { license-ids: (unwrap! (as-max-len? (append (get license-ids current-licenses) new-license-id) u100) ERR_TOO_MANY_LICENSES) }
    )
    (var-set license-id-nonce new-license-id)
    (ok new-license-id)
  )
)

(define-public (revoke-license (license-id uint))
  (let
    ((license (unwrap! (map-get? licenses { license-id: license-id }) ERR_LICENSE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get licensor license)) ERR_UNAUTHORIZED)
    (ok (map-set licenses
      { license-id: license-id }
      (merge license { status: "revoked" })
    ))
  )
)

(define-read-only (get-license-info (license-id uint))
  (map-get? licenses { license-id: license-id })
)

(define-read-only (get-asset-licenses (asset-id uint))
  (map-get? asset-licenses { asset-id: asset-id })
)

(define-constant ERR_LICENSE_NOT_FOUND (err u404))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_TOO_MANY_LICENSES (err u100))

