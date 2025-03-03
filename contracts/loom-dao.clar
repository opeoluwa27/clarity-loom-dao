;; LoomDAO Main Contract

;; Constants
(define-constant ERR-NOT-TOKEN-OWNER (err u1))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u2))
(define-constant ERR-PROPOSAL-EXPIRED (err u3))
(define-constant ERR-ALREADY-VOTED (err u4))
(define-constant ERR-INVALID-QUORUM (err u5))
(define-constant QUORUM-THRESHOLD u500000) ;; 50% of total supply needed

;; Data Maps
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
    deadline: uint,
    executed: bool
  })

(define-map votes
  { proposal-id: uint, voter: principal }
  { 
    voted: bool,
    weight: uint
  })

(define-map vote-delegates
  { delegator: principal }
  { delegate: principal })

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
          deadline: deadline,
          executed: false
        })
      (var-set proposal-count (+ proposal-id u1))
      (ok proposal-id))))

;; Vote on proposal
(define-public (vote (proposal-id uint) (vote-type bool))
  (let (
    (proposal (unwrap! (map-get? proposals {proposal-id: proposal-id}) ERR-PROPOSAL-NOT-FOUND))
    (voter-balance (contract-call? .loom-token get-balance tx-sender))
    (vote-weight (get-vote-weight tx-sender))
  )
    (asserts! (< block-height (get deadline proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
    (map-set votes {proposal-id: proposal-id, voter: tx-sender} {voted: true, weight: vote-weight})
    (if vote-type
      (map-set proposals {proposal-id: proposal-id}
        (merge proposal {yes-votes: (+ (get yes-votes proposal) vote-weight)}))
      (map-set proposals {proposal-id: proposal-id}
        (merge proposal {no-votes: (+ (get no-votes proposal) vote-weight)})))
    (ok true)))

;; Execute proposal
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals {proposal-id: proposal-id}) ERR-PROPOSAL-NOT-FOUND))
    (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
  )
    (asserts! (>= total-votes QUORUM-THRESHOLD) ERR-INVALID-QUORUM)
    (asserts! (> (get yes-votes proposal) (get no-votes proposal)) (err u6))
    (asserts! (not (get executed proposal)) (err u7))
    (asserts! (> block-height (get deadline proposal)) (err u8))
    
    (match (contract-call? .loom-treasury fund-project 
      proposal-id 
      (get creator proposal) 
      (get amount proposal))
      success (begin
        (map-set proposals {proposal-id: proposal-id}
          (merge proposal {executed: true, status: "executed"}))
        (ok true))
      error (err u9))))

;; Delegate votes
(define-public (delegate-vote (delegate-to principal))
  (begin
    (map-set vote-delegates {delegator: tx-sender} {delegate: delegate-to})
    (ok true)))

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals {proposal-id: proposal-id}))

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter}))

(define-read-only (get-vote-weight (voter principal))
  (let ((delegation (map-get? vote-delegates {delegator: voter})))
    (if (is-some delegation)
      (contract-call? .loom-token get-balance (get delegate (unwrap-panic delegation)))
      (contract-call? .loom-token get-balance voter))))
