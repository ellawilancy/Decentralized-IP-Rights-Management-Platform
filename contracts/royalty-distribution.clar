;; Royalty Distribution Contract

(define-fungible-token royalty-token)

(define-map royalty-settings
  { asset-id: uint }
  {
    royalty-percentage: uint,
    beneficiaries: (list 10 { address: principal, share: uint })
  }
)

(define-map royalty-balances
  { address: principal }
  { balance: uint }
)

(define-public (set-royalty-settings
  (asset-id uint)
  (royalty-percentage uint)
  (beneficiaries (list 10 { address: principal, share: uint }))
)
  (begin
    (asserts! (<= royalty-percentage u1000) ERR_INVALID_PERCENTAGE)
    (asserts! (is-eq u10000 (fold + (map get-share beneficiaries) u0)) ERR_INVALID_SHARES)
    (ok (map-set royalty-settings
      { asset-id: asset-id }
      {
        royalty-percentage: royalty-percentage,
        beneficiaries: beneficiaries
      }
    ))
  )
)

(define-public (distribute-royalties (asset-id uint) (amount uint))
  (let
    ((settings (unwrap! (map-get? royalty-settings { asset-id: asset-id }) ERR_NO_ROYALTY_SETTINGS))
     (royalty-amount (/ (* amount (get royalty-percentage settings)) u10000)))
    (map distribute-to-beneficiary (get beneficiaries settings))
    (ok royalty-amount)
  )
)

(define-private (distribute-to-beneficiary (beneficiary { address: principal, share: uint }))
  (let
    ((address (get address beneficiary))
     (share (get share beneficiary))
     (current-balance (default-to { balance: u0 } (map-get? royalty-balances { address: address }))))
    (map-set royalty-balances
      { address: address }
      { balance: (+ (get balance current-balance) share) }
    )
  )
)

(define-public (withdraw-royalties (amount uint))
  (let
    ((balance (default-to { balance: u0 } (map-get? royalty-balances { address: tx-sender }))))
    (asserts! (>= (get balance balance) amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-mint? royalty-token amount tx-sender))
    (map-set royalty-balances
      { address: tx-sender }
      { balance: (- (get balance balance) amount) }
    )
    (ok amount)
  )
)

(define-read-only (get-royalty-settings (asset-id uint))
  (map-get? royalty-settings { asset-id: asset-id })
)

(define-read-only (get-royalty-balance (address principal))
  (default-to { balance: u0 } (map-get? royalty-balances { address: address }))
)

(define-private (get-share (beneficiary { address: principal, share: uint }))
  (get share beneficiary)
)

(define-constant ERR_INVALID_PERCENTAGE (err u400))
(define-constant ERR_INVALID_SHARES (err u400))
(define-constant ERR_NO_ROYALTY_SETTINGS (err u404))
(define-constant ERR_INSUFFICIENT_BALANCE (err u401))

