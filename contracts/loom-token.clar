;; LOOM Governance Token
(define-fungible-token loom-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))

(define-data-var token-uri (string-utf8 256) "ipfs://QmXYZ...")

;; Token transfer
(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err u1))
    (ft-transfer? loom-token amount sender recipient)
  )
)

;; Mint tokens - only owner
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? loom-token amount recipient)
  )
)
