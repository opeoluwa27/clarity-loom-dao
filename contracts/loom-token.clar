;; LOOM Governance Token
;; Implements SIP-010 trait for fungible tokens

(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-fungible-token loom-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))

(define-data-var token-uri (string-utf8 256) "ipfs://QmXYZ...")
(define-data-var token-name (string-ascii 32) "LOOM Token")
(define-data-var token-symbol (string-ascii 10) "LOOM")
(define-data-var token-decimals uint u6)

;; SIP-010 Implementation
(define-read-only (get-name)
  (ok (var-get token-name)))

(define-read-only (get-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-decimals)
  (ok (var-get token-decimals)))

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance loom-token account)))

(define-read-only (get-total-supply)
  (ok (ft-get-supply loom-token)))

(define-read-only (get-token-uri)
  (ok (var-get token-uri)))

;; Token transfer
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) (err u1))
    (match (ft-transfer? loom-token amount sender recipient)
      success (ok success)
      error (err error))))

;; Mint tokens - only owner
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? loom-token amount recipient)))

;; Burn tokens
(define-public (burn (amount uint) (owner principal))
  (begin
    (asserts! (is-eq tx-sender owner) (err u1))
    (ft-burn? loom-token amount owner)))
