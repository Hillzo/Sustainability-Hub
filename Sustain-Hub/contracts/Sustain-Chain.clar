;; Impact Sustainability Tracking Smart Contract
;; A comprehensive system for tracking environmental and social impact metrics

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_INPUT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_PERIOD (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_VERIFICATION (err u106))
(define-constant ERR_EXPIRED (err u107))

;; Impact category constants
(define-constant CARBON_REDUCTION u1)
(define-constant RENEWABLE_ENERGY u2)
(define-constant WASTE_REDUCTION u3)
(define-constant WATER_CONSERVATION u4)
(define-constant BIODIVERSITY u5)
(define-constant SOCIAL_IMPACT u6)

;; Input validation constants
(define-constant MAX_FEE u1000000000) ;; 1000 STX max fee
(define-constant MAX_STAKE u100000000000) ;; 100,000 STX max stake
(define-constant MAX_PROJECT_ID u1000000) ;; Max project ID
(define-constant MAX_RECORD_ID u1000000) ;; Max record ID
(define-constant MAX_MILESTONE_ID u1000) ;; Max milestone ID
(define-constant MAX_REWARD u10000000000) ;; 10,000 STX max reward

;; Data Variables
(define-data-var contract-active bool true)
(define-data-var total-projects uint u0)
(define-data-var verification-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var min-stake-amount uint u5000000) ;; 5 STX minimum stake

;; Data Maps

;; Project registry
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    description: (string-utf8 500),
    category: uint,
    target-impact: uint,
    current-impact: uint,
    created-at: uint,
    expires-at: uint,
    verified: bool,
    stake-amount: uint,
    active: bool
  }
)

;; Impact records for detailed tracking
(define-map impact-records
  { project-id: uint, record-id: uint }
  {
    reporter: principal,
    impact-value: uint,
    evidence-hash: (string-ascii 64),
    timestamp: uint,
    verified: bool,
    verifier: (optional principal)
  }
)

;; Project impact record counters
(define-map project-record-counts
  { project-id: uint }
  { count: uint }
)

;; Verifier registry
(define-map verifiers
  { verifier: principal }
  {
    reputation: uint,
    total-verifications: uint,
    successful-verifications: uint,
    registered-at: uint,
    active: bool
  }
)

;; Stakeholder balances
(define-map stakeholder-balances
  { stakeholder: principal }
  { balance: uint }
)

;; Project stakeholder tracking
(define-map project-stakeholders
  { project-id: uint, stakeholder: principal }
  { stake-amount: uint, joined-at: uint }
)

;; Impact achievements and milestones
(define-map project-milestones
  { project-id: uint, milestone-id: uint }
  {
    description: (string-utf8 200),
    target-value: uint,
    achieved: bool,
    achieved-at: (optional uint),
    reward-amount: uint
  }
)

;; Milestone counters
(define-map project-milestone-counts
  { project-id: uint }
  { count: uint }
)

;; Utility Functions

;; Get current block height as timestamp
(define-private (get-block-timestamp)
  block-height
)

;; Validate impact category
(define-private (is-valid-category (category uint))
  (and (>= category u1) (<= category u6))
)

;; Validate project ID
(define-private (is-valid-project-id (project-id uint))
  (and (> project-id u0) (<= project-id MAX_PROJECT_ID))
)

;; Validate record ID
(define-private (is-valid-record-id (record-id uint))
  (and (> record-id u0) (<= record-id MAX_RECORD_ID))
)

;; Validate milestone ID
(define-private (is-valid-milestone-id (milestone-id uint))
  (and (> milestone-id u0) (<= milestone-id MAX_MILESTONE_ID))
)

;; Validate fee amount
(define-private (is-valid-fee (fee uint))
  (and (> fee u0) (<= fee MAX_FEE))
)

;; Validate stake amount
(define-private (is-valid-stake-amount (amount uint))
  (and (> amount u0) (<= amount MAX_STAKE))
)

;; Validate reward amount
(define-private (is-valid-reward-amount (amount uint))
  (<= amount MAX_REWARD)
)

;; Validate string is not empty
(define-private (is-non-empty-string-ascii (str (string-ascii 100)))
  (> (len str) u0)
)

;; Validate UTF8 string is not empty
(define-private (is-non-empty-string-utf8 (str (string-utf8 500)))
  (> (len str) u0)
)

;; Validate UTF8 200 string is not empty
(define-private (is-non-empty-string-utf8-200 (str (string-utf8 200)))
  (> (len str) u0)
)

;; Validate evidence hash
(define-private (is-valid-evidence-hash (hash (string-ascii 64)))
  (and (> (len hash) u0) (<= (len hash) u64))
)

;; Calculate reputation score
(define-private (calculate-reputation (successful uint) (total uint))
  (if (is-eq total u0)
    u0
    (* (/ (* successful u100) total) u10)
  )
)

;; Administrative Functions

;; Update contract settings (owner only)
(define-public (update-verification-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-valid-fee new-fee) ERR_INVALID_INPUT)
    (var-set verification-fee new-fee)
    (ok true)
  )
)

(define-public (update-min-stake-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-valid-stake-amount new-amount) ERR_INVALID_INPUT)
    (var-set min-stake-amount new-amount)
    (ok true)
  )
)

(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Project Management Functions

;; Create new sustainability project
(define-public (create-project 
  (name (string-ascii 100))
  (description (string-utf8 500))
  (category uint)
  (target-impact uint)
  (duration-blocks uint)
  (stake-amount uint))
  (let
    (
      (project-id (+ (var-get total-projects) u1))
      (expires-at (+ (get-block-timestamp) duration-blocks))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-non-empty-string-ascii name) ERR_INVALID_INPUT)
    (asserts! (is-non-empty-string-utf8 description) ERR_INVALID_INPUT)
    (asserts! (is-valid-category category) ERR_INVALID_INPUT)
    (asserts! (> target-impact u0) ERR_INVALID_INPUT)
    (asserts! (> duration-blocks u0) ERR_INVALID_INPUT)
    (asserts! (>= stake-amount (var-get min-stake-amount)) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-valid-stake-amount stake-amount) ERR_INVALID_INPUT)
    (asserts! (<= project-id MAX_PROJECT_ID) ERR_INVALID_INPUT)
    
    ;; Transfer stake amount from sender
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    ;; Create project record
    (map-set projects
      { project-id: project-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        category: category,
        target-impact: target-impact,
        current-impact: u0,
        created-at: (get-block-timestamp),
        expires-at: expires-at,
        verified: false,
        stake-amount: stake-amount,
        active: true
      }
    )
    
    ;; Initialize record count
    (map-set project-record-counts
      { project-id: project-id }
      { count: u0 }
    )
    
    ;; Initialize milestone count
    (map-set project-milestone-counts
      { project-id: project-id }
      { count: u0 }
    )
    
    ;; Update total projects counter
    (var-set total-projects project-id)
    
    (ok project-id)
  )
)

;; Add stakeholder to project
(define-public (add-stakeholder (project-id uint) (stake-amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
      (current-balance (default-to u0 (get balance (map-get? stakeholder-balances { stakeholder: tx-sender }))))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-project-id project-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-stake-amount stake-amount) ERR_INVALID_INPUT)
    (asserts! (get active project) ERR_INVALID_INPUT)
    (asserts! (> stake-amount u0) ERR_INVALID_INPUT)
    (asserts! (< (get-block-timestamp) (get expires-at project)) ERR_EXPIRED)
    
    ;; Transfer stake amount
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    ;; Record stakeholder participation
    (map-set project-stakeholders
      { project-id: project-id, stakeholder: tx-sender }
      { stake-amount: stake-amount, joined-at: (get-block-timestamp) }
    )
    
    ;; Update stakeholder balance
    (map-set stakeholder-balances
      { stakeholder: tx-sender }
      { balance: (+ current-balance stake-amount) }
    )
    
    (ok true)
  )
)

;; Impact Reporting Functions

;; Submit impact record
(define-public (submit-impact-record
  (project-id uint)
  (impact-value uint)
  (evidence-hash (string-ascii 64)))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
      (record-count (default-to u0 (get count (map-get? project-record-counts { project-id: project-id }))))
      (new-record-id (+ record-count u1))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-project-id project-id) ERR_INVALID_INPUT)
    (asserts! (> impact-value u0) ERR_INVALID_INPUT)
    (asserts! (is-valid-evidence-hash evidence-hash) ERR_INVALID_INPUT)
    (asserts! (get active project) ERR_INVALID_INPUT)
    (asserts! (or (is-eq tx-sender (get owner project)) 
                  (is-some (map-get? project-stakeholders { project-id: project-id, stakeholder: tx-sender })))
              ERR_UNAUTHORIZED)
    (asserts! (< (get-block-timestamp) (get expires-at project)) ERR_EXPIRED)
    (asserts! (<= new-record-id MAX_RECORD_ID) ERR_INVALID_INPUT)
    
    ;; Create impact record
    (map-set impact-records
      { project-id: project-id, record-id: new-record-id }
      {
        reporter: tx-sender,
        impact-value: impact-value,
        evidence-hash: evidence-hash,
        timestamp: (get-block-timestamp),
        verified: false,
        verifier: none
      }
    )
    
    ;; Update record count
    (map-set project-record-counts
      { project-id: project-id }
      { count: new-record-id }
    )
    
    (ok new-record-id)
  )
)

;; Verification System

;; Register as verifier
(define-public (register-verifier)
  (begin
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verifiers { verifier: tx-sender })) ERR_ALREADY_EXISTS)
    
    ;; Pay verification registration fee
    (try! (stx-transfer? (var-get verification-fee) tx-sender CONTRACT_OWNER))
    
    (map-set verifiers
      { verifier: tx-sender }
      {
        reputation: u0,
        total-verifications: u0,
        successful-verifications: u0,
        registered-at: (get-block-timestamp),
        active: true
      }
    )
    
    (ok true)
  )
)

;; Verify impact record
(define-public (verify-impact-record (project-id uint) (record-id uint) (approved bool))
  (let
    (
      (verifier-data (unwrap! (map-get? verifiers { verifier: tx-sender }) ERR_UNAUTHORIZED))
      (record (unwrap! (map-get? impact-records { project-id: project-id, record-id: record-id }) ERR_NOT_FOUND))
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-project-id project-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-record-id record-id) ERR_INVALID_INPUT)
    (asserts! (get active verifier-data) ERR_UNAUTHORIZED)
    (asserts! (not (get verified record)) ERR_ALREADY_EXISTS)
    
    ;; Update impact record
    (map-set impact-records
      { project-id: project-id, record-id: record-id }
      (merge record {
        verified: approved,
        verifier: (some tx-sender)
      })
    )
    
    ;; If approved, update project impact
    (if approved
      (map-set projects
        { project-id: project-id }
        (merge project {
          current-impact: (+ (get current-impact project) (get impact-value record))
        })
      )
      true
    )
    
    ;; Update verifier statistics
    (map-set verifiers
      { verifier: tx-sender }
      (merge verifier-data {
        total-verifications: (+ (get total-verifications verifier-data) u1),
        successful-verifications: (if approved 
                                    (+ (get successful-verifications verifier-data) u1)
                                    (get successful-verifications verifier-data)),
        reputation: (calculate-reputation 
                      (if approved 
                        (+ (get successful-verifications verifier-data) u1)
                        (get successful-verifications verifier-data))
                      (+ (get total-verifications verifier-data) u1))
      })
    )
    
    (ok approved)
  )
)

;; Milestone Management

;; Add milestone to project
(define-public (add-milestone 
  (project-id uint)
  (description (string-utf8 200))
  (target-value uint)
  (reward-amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
      (milestone-count (default-to u0 (get count (map-get? project-milestone-counts { project-id: project-id }))))
      (new-milestone-id (+ milestone-count u1))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-project-id project-id) ERR_INVALID_INPUT)
    (asserts! (is-non-empty-string-utf8-200 description) ERR_INVALID_INPUT)
    (asserts! (> target-value u0) ERR_INVALID_INPUT)
    (asserts! (is-valid-reward-amount reward-amount) ERR_INVALID_INPUT)
    (asserts! (is-eq tx-sender (get owner project)) ERR_UNAUTHORIZED)
    (asserts! (get active project) ERR_INVALID_INPUT)
    (asserts! (<= new-milestone-id MAX_MILESTONE_ID) ERR_INVALID_INPUT)
    
    (map-set project-milestones
      { project-id: project-id, milestone-id: new-milestone-id }
      {
        description: description,
        target-value: target-value,
        achieved: false,
        achieved-at: none,
        reward-amount: reward-amount
      }
    )
    
    (map-set project-milestone-counts
      { project-id: project-id }
      { count: new-milestone-id }
    )
    
    (ok new-milestone-id)
  )
)

;; Check and update milestone achievement
(define-public (check-milestone-achievement (project-id uint) (milestone-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
      (milestone (unwrap! (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id }) ERR_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-project-id project-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-milestone-id milestone-id) ERR_INVALID_INPUT)
    (asserts! (not (get achieved milestone)) ERR_ALREADY_EXISTS)
    (asserts! (>= (get current-impact project) (get target-value milestone)) ERR_INVALID_INPUT)
    
    ;; Mark milestone as achieved
    (map-set project-milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone {
        achieved: true,
        achieved-at: (some (get-block-timestamp))
      })
    )
    
    ;; Transfer reward if available
    (if (> (get reward-amount milestone) u0)
      (try! (as-contract (stx-transfer? (get reward-amount milestone) tx-sender (get owner project))))
      true
    )
    
    (ok true)
  )
)

;; Read-only Functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get impact record
(define-read-only (get-impact-record (project-id uint) (record-id uint))
  (map-get? impact-records { project-id: project-id, record-id: record-id })
)

;; Get verifier details
(define-read-only (get-verifier (verifier principal))
  (map-get? verifiers { verifier: verifier })
)

;; Get project milestone
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Get stakeholder balance
(define-read-only (get-stakeholder-balance (stakeholder principal))
  (default-to u0 (get balance (map-get? stakeholder-balances { stakeholder: stakeholder })))
)

;; Get project record count
(define-read-only (get-project-record-count (project-id uint))
  (default-to u0 (get count (map-get? project-record-counts { project-id: project-id })))
)

;; Get project milestone count
(define-read-only (get-project-milestone-count (project-id uint))
  (default-to u0 (get count (map-get? project-milestone-counts { project-id: project-id })))
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-projects: (var-get total-projects),
    verification-fee: (var-get verification-fee),
    min-stake-amount: (var-get min-stake-amount),
    contract-active: (var-get contract-active),
    contract-owner: CONTRACT_OWNER
  }
)

;; Check if project is active and not expired
(define-read-only (is-project-active (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project (and (get active project) (< (get-block-timestamp) (get expires-at project)))
    false
  )
)

;; Calculate project progress percentage
(define-read-only (get-project-progress (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project (if (> (get target-impact project) u0)
              (let ((progress (/ (* (get current-impact project) u100) (get target-impact project))))
                (if (> progress u100) u100 progress))
              u0)
    u0
  )
)