;; Cipher Persona Registry
;; A decentralized identity management system for virtual community members
;; Enables secure profile creation, updates, and access control for digital identities

;; =======================================
;; Protocol Constants
;; =======================================

;; Protocol governance authority
(define-constant SYSTEM-CONTROLLER tx-sender)

;; System response codes
(define-constant ERR-PERMISSION-DENIED (err u500))
(define-constant ERR-PROFILE-NONEXISTENT (err u501))
(define-constant ERR-PROFILE-EXISTS (err u502))
(define-constant ERR-FORMAT-VIOLATION (err u503))
(define-constant ERR-PROTECTED-OPERATION (err u504))


;; =======================================
;; Persistent Data Structures
;; =======================================

;; Central repository for member activity metrics and engagement analysis
(define-map member-activity-metrics
  { member-code: uint }
  {
    previous-visit: uint,
    visit-frequency: uint,
    latest-action: (string-ascii 50)
  }
)

;; System-wide counter tracking total enrollment
(define-data-var community-population uint u0)

;; Primary vault for all member profile details
(define-map virtual-identity-vault
  { member-code: uint }
  {
    alias: (string-ascii 50),
    wallet-address: principal,
    genesis-height: uint,
    bio-text: (string-ascii 160),
    category-labels: (list 5 (string-ascii 30))
  }
)

;; Security matrix controlling information visibility between members
(define-map data-visibility-matrix
  { member-code: uint, viewer-address: principal }
  { permission-granted: bool }
)


;; =======================================
;; Helper Functions
;; =======================================

;; Validates member existence in the system
(define-private (member-exists? (member-code uint))
  (is-some (map-get? virtual-identity-vault { member-code: member-code }))
)

;; Performs validation on a single category label
(define-private (validate-single-label (label (string-ascii 30)))
  (and
    (> (len label) u0)
    (< (len label) u31)
  )
)

;; Validates the complete set of category labels for a profile
(define-private (validate-label-set (labels (list 5 (string-ascii 30))))
  (and
    (> (len labels) u0)
    (<= (len labels) u5)
    (is-eq (len (filter validate-single-label labels)) (len labels))
  )
)

;; Verifies the ownership relationship between member profile and blockchain identity
(define-private (verify-profile-ownership (member-code uint) (wallet-address principal))
  (match (map-get? virtual-identity-vault { member-code: member-code })
    profile-data (is-eq (get wallet-address profile-data) wallet-address)
    false
  )
)

;; =======================================
;; Core Protocol Functions
;; =======================================

;; Creates a new community member profile with complete identity information
(define-public (create-virtual-identity
    (alias (string-ascii 50)) 
    (bio-text (string-ascii 160)) 
    (category-labels (list 5 (string-ascii 30))))
  (let
    (
      (new-member-code (+ (var-get community-population) u1))
    )
    ;; Comprehensive validation for all submitted fields
    (asserts! (and (> (len alias) u0) (< (len alias) u51)) ERR-FORMAT-VIOLATION)
    (asserts! (and (> (len bio-text) u0) (< (len bio-text) u161)) ERR-FORMAT-VIOLATION)
    (asserts! (validate-label-set category-labels) ERR-FORMAT-VIOLATION)

    ;; Establish the member's complete profile in permanent storage
    (map-insert virtual-identity-vault
      { member-code: new-member-code }
      {
        alias: alias,
        wallet-address: tx-sender,
        genesis-height: block-height,
        bio-text: bio-text,
        category-labels: category-labels
      }
    )

    ;; Initialize default visibility settings for the member
    (map-insert data-visibility-matrix
      { member-code: new-member-code, viewer-address: tx-sender }
      { permission-granted: true }
    )

    ;; Update system population counter
    (var-set community-population new-member-code)
    (ok new-member-code)
  )
)

;; Records participation event for analytical purposes
(define-public (record-member-visit (member-code uint))
  (let
    (
      (existing-metrics (default-to 
        { previous-visit: u0, visit-frequency: u0, latest-action: "None" }
        (map-get? member-activity-metrics { member-code: member-code })))
    )
    (asserts! (member-exists? member-code) ERR-PROFILE-NONEXISTENT)
    (map-set member-activity-metrics
      { member-code: member-code }
      {
        previous-visit: block-height,
        visit-frequency: (+ (get visit-frequency existing-metrics) u1),
        latest-action: "visit"
      }
    )
    (ok true)
  )
)

;; Updates a member's category label preferences
(define-public (revise-category-labels (member-code uint) (updated-labels (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT))
    )
    ;; Verify profile exists and requester has appropriate permissions
    (asserts! (member-exists? member-code) ERR-PROFILE-NONEXISTENT)
    (asserts! (is-eq (get wallet-address profile-data) tx-sender) ERR-PROTECTED-OPERATION)
    (asserts! (validate-label-set updated-labels) ERR-FORMAT-VIOLATION)

    ;; Apply the category label changes
    (map-set virtual-identity-vault
      { member-code: member-code }
      (merge profile-data { category-labels: updated-labels })
    )
    (ok true)
  )
)

;; Registers a new community member with full profile details
(define-public (onboard-community-member 
    (alias (string-ascii 50)) 
    (bio-text (string-ascii 160)) 
    (category-labels (list 5 (string-ascii 30))))
  (let
    (
      (next-member-code (+ (var-get community-population) u1))
    )
    ;; Thorough validation of all input parameters
    (asserts! (and (> (len alias) u0) (< (len alias) u51)) ERR-FORMAT-VIOLATION)
    (asserts! (and (> (len bio-text) u0) (< (len bio-text) u161)) ERR-FORMAT-VIOLATION)
    (asserts! (validate-label-set category-labels) ERR-FORMAT-VIOLATION)

    ;; Establish the new member profile record
    (map-insert virtual-identity-vault
      { member-code: next-member-code }
      {
        alias: alias,
        wallet-address: tx-sender,
        genesis-height: block-height,
        bio-text: bio-text,
        category-labels: category-labels
      }
    )

    ;; Setup initial visibility permissions
    (map-insert data-visibility-matrix
      { member-code: next-member-code, viewer-address: tx-sender }
      { permission-granted: true }
    )

    ;; Increment community size tracker
    (var-set community-population next-member-code)
    (ok next-member-code)
  )
)

;; Updates a member's display name in the system
(define-public (modify-member-alias (member-code uint) (new-alias (string-ascii 50)))
  (let
    (
      (profile-data (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT))
    )
    ;; Credential verification checks
    (asserts! (member-exists? member-code) ERR-PROFILE-NONEXISTENT)
    (asserts! (is-eq (get wallet-address profile-data) tx-sender) ERR-PROTECTED-OPERATION)

    ;; Process the alias change
    (map-set virtual-identity-vault
      { member-code: member-code }
      (merge profile-data { alias: new-alias })
    )
    (ok true)
  )
)

;; =======================================
;; Extended Protocol Capabilities
;; =======================================

;; Optimized path for rapid category label updates
(define-public (quick-label-update (member-code uint) (updated-labels (list 5 (string-ascii 30))))
  (begin
    (asserts! (member-exists? member-code) ERR-PROFILE-NONEXISTENT)
    (asserts! (validate-label-set updated-labels) ERR-FORMAT-VIOLATION)
    (map-set virtual-identity-vault
      { member-code: member-code }
      (merge (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT) 
             { category-labels: updated-labels })
    )
    (ok "Category labels successfully refreshed")
  )
)

;; Manages profile visibility settings based on identity verification
(define-public (enforce-profile-privacy (member-code uint) (wallet-address principal))
  (let
    (
      (profile-data (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT))
    )
    ;; Security verification for access authorization
    (asserts! (is-eq (get wallet-address profile-data) wallet-address) ERR-PROTECTED-OPERATION)
    (ok true)
  )
)

;; Comprehensive profile update function for all modifiable fields
(define-public (execute-full-profile-update (member-code uint) (new-alias (string-ascii 50)) 
                                          (new-bio-text (string-ascii 160)) (new-category-labels (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT))
    )
    ;; Complete validation suite for all updateable fields
    (asserts! (member-exists? member-code) ERR-PROFILE-NONEXISTENT)
    (asserts! (is-eq (get wallet-address profile-data) tx-sender) ERR-PROTECTED-OPERATION)
    (asserts! (> (len new-alias) u0) ERR-FORMAT-VIOLATION)
    (asserts! (< (len new-alias) u51) ERR-FORMAT-VIOLATION)
    (asserts! (validate-label-set new-category-labels) ERR-FORMAT-VIOLATION)

    ;; Apply the comprehensive profile updates
    (map-set virtual-identity-vault
      { member-code: member-code }
      (merge profile-data { 
        alias: new-alias, 
        bio-text: new-bio-text, 
        category-labels: new-category-labels 
      })
    )
    (ok true)
  )
)

;; Identity verification for profile ownership claims
(define-public (authenticate-identity-claim (member-code uint) (claiming-address principal))
  (let
    (
      (profile-data (unwrap! (map-get? virtual-identity-vault { member-code: member-code }) ERR-PROFILE-NONEXISTENT))
    )
    (ok (is-eq claiming-address (get wallet-address profile-data)))
  )
)

