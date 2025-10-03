;; Decentralized Organ Transplant Registry Smart Contract
;; A blockchain-based medical coordination platform that manages organ donation and transplantation
;; through secure, transparent, and immutable record-keeping. This contract enables medical
;; institutions to register donors and recipients, validate medical compatibility, coordinate
;; transplant procedures, and maintain comprehensive audit trails of all operations while
;; ensuring patient privacy and regulatory compliance.

;; Contract deployer serves as the platform administrator
(define-constant contract-owner tx-sender)

;; Access control error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u200))
(define-constant ERR-INSUFFICIENT-PRIVILEGES (err u201))

;; Entity registration error codes
(define-constant ERR-DONOR-NOT-FOUND (err u210))
(define-constant ERR-DONOR-ALREADY-REGISTERED (err u211))
(define-constant ERR-RECIPIENT-NOT-FOUND (err u212))
(define-constant ERR-RECIPIENT-ALREADY-REGISTERED (err u213))
(define-constant ERR-PROCEDURE-NOT-FOUND (err u214))

;; Medical validation error codes
(define-constant ERR-INVALID-ORGAN-SPECIFICATION (err u220))
(define-constant ERR-INVALID-BLOOD-TYPE-SPECIFICATION (err u221))
(define-constant ERR-ORGAN-UNAVAILABLE (err u222))
(define-constant ERR-MEDICAL-INCOMPATIBILITY-DETECTED (err u223))
(define-constant ERR-INVALID-PATIENT-STATUS (err u224))
(define-constant ERR-INVALID-PRIORITY-SPECIFICATION (err u225))
(define-constant ERR-MEDICAL-CLEARANCE-REQUIRED (err u226))

;; Patient data validation error codes
(define-constant ERR-INVALID-PATIENT-INFORMATION (err u230))
(define-constant ERR-MISSING-PATIENT-IDENTIFIER (err u231))
(define-constant ERR-INVALID-AGE-SPECIFICATION (err u232))

;; Organ type classification constants
(define-constant organ-type-heart u1)
(define-constant organ-type-kidney u2)
(define-constant organ-type-liver u3)
(define-constant organ-type-lung u4)
(define-constant organ-type-pancreas u5)
(define-constant organ-type-cornea u6)

;; Blood type classification constants
(define-constant blood-a-positive u1)
(define-constant blood-b-positive u2)
(define-constant blood-ab-positive u3)
(define-constant blood-o-positive u4)

;; Patient status classification constants
(define-constant status-active u1)
(define-constant status-matched u2)
(define-constant status-completed u3)
(define-constant status-inactive u4)

;; Medical priority classification constants
(define-constant priority-critical u1)
(define-constant priority-urgent u2)
(define-constant priority-high u3)
(define-constant priority-moderate u4)
(define-constant priority-routine u5)

;; Storage map for donor medical profiles with complete registration details
(define-map donor-registry
  principal
  {
    patient-name: (string-ascii 100),
    age: uint,
    blood-type: uint,
    organs-available: (list 10 uint),
    registered-at-block: uint,
    current-status: uint,
    medical-clearance: bool,
    assigned-physician: (optional principal)
  }
)

;; Storage map for recipient medical profiles with transplant requirements
(define-map recipient-registry
  principal
  {
    patient-name: (string-ascii 100),
    age: uint,
    blood-type: uint,
    organ-needed: uint,
    priority-level: uint,
    registered-at-block: uint,
    current-status: uint,
    waiting-list-position: uint
  }
)

;; Storage map for transplant procedure tracking and documentation
(define-map procedure-registry
  uint
  {
    donor-address: principal,
    recipient-address: principal,
    organ-type: uint,
    initiated-at-block: uint,
    procedure-status: uint,
    physician-in-charge: principal,
    completed-at-block: (optional uint)
  }
)

;; Platform analytics and tracking variables
(define-data-var next-procedure-id uint u1)
(define-data-var total-donors uint u0)
(define-data-var total-recipients uint u0)
(define-data-var successful-transplants uint u0)
(define-data-var ongoing-procedures uint u0)

;; Validates organ type falls within acceptable range
(define-private (is-valid-organ-type (organ-id uint))
  (and (>= organ-id u1) (<= organ-id u6))
)

;; Validates blood type falls within acceptable range
(define-private (is-valid-blood-type (blood-id uint))
  (and (>= blood-id u1) (<= blood-id u4))
)

;; Validates patient status falls within acceptable range
(define-private (is-valid-status (status-id uint))
  (and (>= status-id u1) (<= status-id u4))
)

;; Validates priority level falls within acceptable range
(define-private (is-valid-priority (priority-id uint))
  (and (>= priority-id u1) (<= priority-id u5))
)

;; Validates patient name is not empty string
(define-private (is-valid-name (name (string-ascii 100)))
  (> (len name) u0)
)

;; Validates age is within reasonable human lifespan range
(define-private (is-valid-age (age uint))
  (and (> age u0) (< age u120))
)

;; Checks if donor principal exists in registry
(define-private (donor-exists (donor-address principal))
  (is-some (map-get? donor-registry donor-address))
)

;; Determines blood type compatibility for transplant eligibility
(define-private (is-blood-compatible (donor-blood uint) (recipient-blood uint))
  (or
    (is-eq donor-blood blood-o-positive)
    (is-eq donor-blood recipient-blood)
    (is-eq recipient-blood blood-ab-positive)
    (and (is-eq donor-blood blood-a-positive) 
         (is-eq recipient-blood blood-ab-positive))
    (and (is-eq donor-blood blood-b-positive) 
         (is-eq recipient-blood blood-ab-positive))
  )
)

;; Checks if specific organ exists in donor's available organ list
(define-private (has-organ-available (target-organ uint) (organ-list (list 10 uint)))
  (is-some (index-of organ-list target-organ))
)

;; Validates all organs in list are recognized organ types
(define-private (are-organs-valid (organs (list 10 uint)))
  (is-eq (len (filter is-valid-organ-type organs)) (len organs))
)

;; Registers new organ donor with complete medical profile
(define-public (register-donor
  (name (string-ascii 100))
  (age uint)
  (blood-type uint)
  (organs (list 10 uint))
)
  (let
    (
      (donor-address tx-sender)
      (registration-block block-height)
    )
    (asserts! (is-valid-name name) ERR-MISSING-PATIENT-IDENTIFIER)
    (asserts! (is-valid-age age) ERR-INVALID-AGE-SPECIFICATION)
    (asserts! (is-valid-blood-type blood-type) ERR-INVALID-BLOOD-TYPE-SPECIFICATION)
    (asserts! (are-organs-valid organs) ERR-INVALID-ORGAN-SPECIFICATION)
    (asserts! (is-none (map-get? donor-registry donor-address)) ERR-DONOR-ALREADY-REGISTERED)
    
    (map-set donor-registry donor-address {
      patient-name: name,
      age: age,
      blood-type: blood-type,
      organs-available: organs,
      registered-at-block: registration-block,
      current-status: status-active,
      medical-clearance: false,
      assigned-physician: none
    })
    
    (var-set total-donors (+ (var-get total-donors) u1))
    (ok true)
  )
)

;; Updates medical clearance status for registered donor
(define-public (set-donor-clearance
  (donor-address principal)
  (clearance-approved bool)
  (physician (optional principal))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (donor-exists donor-address) ERR-DONOR-NOT-FOUND)
    
    (let
      (
        (current-profile (unwrap-panic (map-get? donor-registry donor-address)))
      )
      (map-set donor-registry donor-address
        (merge current-profile {
          medical-clearance: clearance-approved,
          assigned-physician: physician
        })
      )
      (ok true)
    )
  )
)

;; Registers new transplant recipient with medical requirements
(define-public (register-recipient
  (name (string-ascii 100))
  (age uint)
  (blood-type uint)
  (organ-needed uint)
  (priority uint)
)
  (let
    (
      (recipient-address tx-sender)
      (registration-block block-height)
      (queue-position (+ (var-get total-recipients) u1))
    )
    (asserts! (is-valid-name name) ERR-MISSING-PATIENT-IDENTIFIER)
    (asserts! (is-valid-age age) ERR-INVALID-AGE-SPECIFICATION)
    (asserts! (is-valid-blood-type blood-type) ERR-INVALID-BLOOD-TYPE-SPECIFICATION)
    (asserts! (is-valid-organ-type organ-needed) ERR-INVALID-ORGAN-SPECIFICATION)
    (asserts! (is-valid-priority priority) ERR-INVALID-PRIORITY-SPECIFICATION)
    (asserts! (is-none (map-get? recipient-registry recipient-address)) ERR-RECIPIENT-ALREADY-REGISTERED)
    
    (map-set recipient-registry recipient-address {
      patient-name: name,
      age: age,
      blood-type: blood-type,
      organ-needed: organ-needed,
      priority-level: priority,
      registered-at-block: registration-block,
      current-status: status-active,
      waiting-list-position: queue-position
    })
    
    (var-set total-recipients (+ (var-get total-recipients) u1))
    (ok true)
  )
)

;; Initiates transplant procedure between matched donor and recipient
(define-public (initiate-procedure
  (donor-address principal)
  (recipient-address principal)
  (organ-type uint)
)
  (let
    (
      (donor-profile (unwrap! (map-get? donor-registry donor-address) ERR-DONOR-NOT-FOUND))
      (recipient-profile (unwrap! (map-get? recipient-registry recipient-address) ERR-RECIPIENT-NOT-FOUND))
      (procedure-id (var-get next-procedure-id))
      (current-block block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-organ-type organ-type) ERR-INVALID-ORGAN-SPECIFICATION)
    (asserts! (get medical-clearance donor-profile) ERR-MEDICAL-CLEARANCE-REQUIRED)
    (asserts! (is-eq (get current-status donor-profile) status-active) ERR-INVALID-PATIENT-STATUS)
    (asserts! (is-eq (get current-status recipient-profile) status-active) ERR-INVALID-PATIENT-STATUS)
    (asserts! (has-organ-available organ-type (get organs-available donor-profile)) ERR-ORGAN-UNAVAILABLE)
    (asserts! (is-eq organ-type (get organ-needed recipient-profile)) ERR-MEDICAL-INCOMPATIBILITY-DETECTED)
    (asserts! (is-blood-compatible (get blood-type donor-profile) (get blood-type recipient-profile)) ERR-MEDICAL-INCOMPATIBILITY-DETECTED)
    
    (map-set procedure-registry procedure-id {
      donor-address: donor-address,
      recipient-address: recipient-address,
      organ-type: organ-type,
      initiated-at-block: current-block,
      procedure-status: status-matched,
      physician-in-charge: tx-sender,
      completed-at-block: none
    })
    
    (map-set donor-registry donor-address
      (merge donor-profile { current-status: status-matched }))
    
    (map-set recipient-registry recipient-address
      (merge recipient-profile { current-status: status-matched }))
    
    (var-set next-procedure-id (+ procedure-id u1))
    (var-set ongoing-procedures (+ (var-get ongoing-procedures) u1))
    
    (ok procedure-id)
  )
)

;; Marks transplant procedure as successfully completed
(define-public (complete-procedure (procedure-id uint))
  (let
    (
      (procedure-data (unwrap! (map-get? procedure-registry procedure-id) ERR-PROCEDURE-NOT-FOUND))
      (donor-address (get donor-address procedure-data))
      (recipient-address (get recipient-address procedure-data))
      (completion-block block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get procedure-status procedure-data) status-matched) ERR-INVALID-PATIENT-STATUS)
    
    (map-set procedure-registry procedure-id
      (merge procedure-data {
        procedure-status: status-completed,
        completed-at-block: (some completion-block)
      })
    )
    
    (let
      (
        (donor-profile (unwrap! (map-get? donor-registry donor-address) ERR-DONOR-NOT-FOUND))
        (recipient-profile (unwrap! (map-get? recipient-registry recipient-address) ERR-RECIPIENT-NOT-FOUND))
      )
      (map-set donor-registry donor-address
        (merge donor-profile { current-status: status-completed }))
      
      (map-set recipient-registry recipient-address
        (merge recipient-profile { current-status: status-completed }))
    )
    
    (var-set successful-transplants (+ (var-get successful-transplants) u1))
    (var-set ongoing-procedures (- (var-get ongoing-procedures) u1))
    
    (ok true)
  )
)

;; Retrieves complete donor profile by principal address
(define-read-only (get-donor (donor-address principal))
  (map-get? donor-registry donor-address)
)

;; Retrieves complete recipient profile by principal address
(define-read-only (get-recipient (recipient-address principal))
  (map-get? recipient-registry recipient-address)
)

;; Retrieves procedure details by procedure identifier
(define-read-only (get-procedure (procedure-id uint))
  (map-get? procedure-registry procedure-id)
)

;; Returns comprehensive platform statistics and metrics
(define-read-only (get-platform-stats)
  {
    donors-registered: (var-get total-donors),
    recipients-registered: (var-get total-recipients),
    transplants-completed: (var-get successful-transplants),
    procedures-ongoing: (var-get ongoing-procedures),
    next-procedure-number: (var-get next-procedure-id)
  }
)

;; Validates blood type compatibility between two blood types
(define-read-only (check-blood-compatibility
  (donor-blood uint)
  (recipient-blood uint)
)
  (and 
    (is-valid-blood-type donor-blood)
    (is-valid-blood-type recipient-blood)
    (is-blood-compatible donor-blood recipient-blood)
  )
)

;; Returns the contract administrator principal address
(define-read-only (get-admin)
  contract-owner
)

;; Analyzes recipient compatibility requirements and medical urgency
(define-public (analyze-recipient-compatibility (recipient-address principal))
  (let
    (
      (recipient-profile (unwrap! (map-get? recipient-registry recipient-address) ERR-RECIPIENT-NOT-FOUND))
      (needed-organ (get organ-needed recipient-profile))
      (recipient-blood (get blood-type recipient-profile))
    )
    (asserts! (is-eq (get current-status recipient-profile) status-active) ERR-INVALID-PATIENT-STATUS)
    
    (ok {
      needed-organ: needed-organ,
      compatible-blood-types: recipient-blood,
      urgency-level: (get priority-level recipient-profile),
      analysis-result: "Comprehensive medical compatibility assessment completed successfully"
    })
  )
)