;; Self-Sovereign Protocol Contract
;; Manages user-controlled identity

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-IDENTITY-EXISTS (err u201))
(define-constant ERR-IDENTITY-NOT-FOUND (err u202))
(define-constant ERR-INVALID-ATTRIBUTES (err u203))

;; Data Maps
(define-map sovereign-identities
  { identity-id: (string-ascii 64) }
  {
    owner: principal,
    attributes: (string-ascii 512),
    created-at: uint,
    updated-at: uint,
    active: bool
  }
)

(define-map identity-attributes
  { identity-id: (string-ascii 64), attribute-key: (string-ascii 64) }
  {
    value: (string-ascii 256),
    visibility: (string-ascii 16),
    updated-at: uint
  }
)

;; Public Functions

;; Create a new sovereign identity
(define-public (create-identity (identity-id (string-ascii 64)) (attributes (string-ascii 512)))
  (let ((existing-identity (map-get? sovereign-identities { identity-id: identity-id })))
    (if (is-some existing-identity)
      ERR-IDENTITY-EXISTS
      (begin
        (map-set sovereign-identities
          { identity-id: identity-id }
          {
            owner: tx-sender,
            attributes: attributes,
            created-at: block-height,
            updated-at: block-height,
            active: true
          }
        )
        (ok true)
      )
    )
  )
)

;; Update identity attributes
(define-public (update-identity (identity-id (string-ascii 64)) (attributes (string-ascii 512)))
  (let ((identity (map-get? sovereign-identities { identity-id: identity-id })))
    (match identity
      identity-data
      (if (is-eq (get owner identity-data) tx-sender)
        (begin
          (map-set sovereign-identities
            { identity-id: identity-id }
            (merge identity-data {
              attributes: attributes,
              updated-at: block-height
            })
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
      )
      ERR-IDENTITY-NOT-FOUND
    )
  )
)

;; Set specific attribute
(define-public (set-attribute (identity-id (string-ascii 64)) (attribute-key (string-ascii 64)) (value (string-ascii 256)) (visibility (string-ascii 16)))
  (let ((identity (map-get? sovereign-identities { identity-id: identity-id })))
    (match identity
      identity-data
      (if (is-eq (get owner identity-data) tx-sender)
        (begin
          (map-set identity-attributes
            { identity-id: identity-id, attribute-key: attribute-key }
            {
              value: value,
              visibility: visibility,
              updated-at: block-height
            }
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
      )
      ERR-IDENTITY-NOT-FOUND
    )
  )
)

;; Deactivate identity
(define-public (deactivate-identity (identity-id (string-ascii 64)))
  (let ((identity (map-get? sovereign-identities { identity-id: identity-id })))
    (match identity
      identity-data
      (if (is-eq (get owner identity-data) tx-sender)
        (begin
          (map-set sovereign-identities
            { identity-id: identity-id }
            (merge identity-data {
              active: false,
              updated-at: block-height
            })
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
      )
      ERR-IDENTITY-NOT-FOUND
    )
  )
)

;; Read-only Functions

;; Get identity information
(define-read-only (get-identity (identity-id (string-ascii 64)))
  (map-get? sovereign-identities { identity-id: identity-id })
)

;; Get specific attribute
(define-read-only (get-attribute (identity-id (string-ascii 64)) (attribute-key (string-ascii 64)))
  (map-get? identity-attributes { identity-id: identity-id, attribute-key: attribute-key })
)

;; Check if identity is active
(define-read-only (is-identity-active (identity-id (string-ascii 64)))
  (match (map-get? sovereign-identities { identity-id: identity-id })
    identity-data (get active identity-data)
    false
  )
)

;; Check identity ownership
(define-read-only (is-owner (identity-id (string-ascii 64)) (user principal))
  (match (map-get? sovereign-identities { identity-id: identity-id })
    identity-data (is-eq (get owner identity-data) user)
    false
  )
)
