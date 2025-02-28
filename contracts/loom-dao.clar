;; LoomDAO Main Contract

;; Constants
(define-constant ERR-NOT-TOKEN-OWNER (err u1))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u2))
(define-constant ERR-PROPOSAL-EXPIRED (err u3))
(define-constant ERR-ALREADY-VOTED (err u4))

(define-map proposals
  { proposal-id: uint }
  {
    creator: principal,
    title: (string-utf8 256),
    description: (string-utf8 1024),
    amount: uint,
    status: (string-ascii 12),
    yes-votes: uint,
    no-votes: uint,
    deadline: uint
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { voted: bool }
)

(define-data-var proposal-count uint u0)

;; Create new proposal
(define-public (create-proposal (title (string-utf8 256)) (description (string-utf8 1024)) (amount uint) (deadline uint))
  (let ((proposal-id (var-get proposal-count)))
    (begin
      (map-set proposals
        { proposal-id: proposal-id }
        {
          creator: tx-sender,
          title: title,
          description: description,
          amount: amount,
          status: "active",
          yes-votes: u0,
          no-votes: u0,
          deadline: deadline
        }
      )
      (var-set proposal-count (+ proposal-id u1))
      (ok proposal-id)
    )
  )
)

;; Vote on proposal
(define-public (vote (proposal-id uint) (vote-type bool))
  (let (
    (proposal (unwrap! (map-get? proposals {proposal-id: proposal-id}) ERR-PROPOSAL-NOT-FOUND))
    (voter-balance (contract-call? .loom-token get-balance tx-sender))
  )
    (asserts! (< block-height (get deadline proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
    (map-set votes {proposal-id: proposal-id, voter: tx-sender} {voted: true})
    (if vote-type
      (map-set proposals {proposal-id: proposal-id}
        (merge proposal {yes-votes: (+ (get yes-votes proposal) voter-balance)}))
      (map-set proposals {proposal-id: proposal-id}
        (merge proposal {no-votes: (+ (get no-votes proposal) voter-balance)}))
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals {proposal-id: proposal-id})
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)
