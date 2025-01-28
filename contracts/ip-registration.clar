;; Intellectual Property Registration Contract

(define-non-fungible-token ip-asset uint)

(define-map ip-asset-info
  { asset-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    creation-date: uint,
    ip-type: (string-ascii 20),
    content-hash: (buff 32)
  }
)

(define-map creator-assets
  { creator: principal }
  { asset-ids: (list 100 uint) }
)

(define-data-var asset-id-nonce uint u0)

(define-public (register-ip-asset
  (title (string-ascii 100))
  (description (string-utf8 500))
  (ip-type (string-ascii 20))
  (content-hash (buff 32))
)
  (let
    ((new-asset-id (+ (var-get asset-id-nonce) u1))
     (creator tx-sender))
    (try! (nft-mint? ip-asset new-asset-id creator))
    (map-set ip-asset-info
      { asset-id: new-asset-id }
      {
        creator: creator,
        title: title,
        description: description,
        creation-date: block-height,
        ip-type: ip-type,
        content-hash: content-hash
      }
    )
    (map-set creator-assets
      { creator: creator }
      { asset-ids: (unwrap! (as-max-len? (append (default-to (list) (get asset-ids (map-get? creator-assets { creator: creator }))) new-asset-id) u100) ERR_TOO_MANY_ASSETS) }
    )
    (var-set asset-id-nonce new-asset-id)
    (ok new-asset-id)
  )
)

(define-read-only (get-ip-asset-info (asset-id uint))
  (map-get? ip-asset-info { asset-id: asset-id })
)

(define-read-only (get-creator-assets (creator principal))
  (map-get? creator-assets { creator: creator })
)

(define-constant ERR_TOO_MANY_ASSETS (err u100))
(define-constant ERR_UNAUTHORIZED (err u401))

