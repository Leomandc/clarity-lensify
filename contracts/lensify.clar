;; Lensify - Photography Copyright Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))
(define-constant err-invalid-expiry (err u104))
(define-constant err-license-expired (err u105))

;; Define NFT
(define-non-fungible-token photo-copyright uint)

;; Events
(define-trait photo-event-trait
  ((emit-photo-registered (uint principal (string-utf8 64)) (response bool uint))
   (emit-copyright-transferred (uint principal principal) (response bool uint))
   (emit-license-granted (uint principal uint) (response bool uint))
   (emit-license-revoked (uint principal) (response bool uint)))
)

;; Data structures
(define-map photos
  uint 
  {
    owner: principal,
    title: (string-utf8 64),
    description: (string-utf8 256),
    timestamp: uint,
    image-uri: (string-utf8 256),
    license-type: (string-utf8 32)
  }
)

(define-map licenses 
  { photo-id: uint, licensee: principal }
  {
    granted-by: principal,
    expires: uint,
    terms: (string-utf8 256)
  }
)

;; Data variables
(define-data-var last-photo-id uint u0)

;; Helper functions
(define-private (is-license-valid (photo-id uint) (licensee principal))
  (match (map-get? licenses { photo-id: photo-id, licensee: licensee })
    license (> (get expires license) block-height)
    false
  )
)

;; Public functions
(define-public (register-photo 
  (title (string-utf8 64))
  (description (string-utf8 256))
  (image-uri (string-utf8 256))
  (license-type (string-utf8 32)))
  (let
    ((photo-id (+ (var-get last-photo-id) u1)))
    (try! (nft-mint? photo-copyright photo-id tx-sender))
    (map-set photos photo-id
      {
        owner: tx-sender,
        title: title,
        description: description,
        timestamp: block-height,
        image-uri: image-uri,
        license-type: license-type
      }
    )
    (var-set last-photo-id photo-id)
    (ok photo-id)
  )
)

(define-public (transfer-copyright
  (photo-id uint)
  (recipient principal))
  (let
    ((photo (unwrap! (map-get? photos photo-id) (err err-not-found))))
    (asserts! (is-eq tx-sender (get owner photo)) (err err-unauthorized))
    (try! (nft-transfer? photo-copyright photo-id tx-sender recipient))
    (ok (map-set photos photo-id
      (merge photo { owner: recipient })))
  )
)

(define-public (grant-license
  (photo-id uint)
  (licensee principal)
  (expires uint)
  (terms (string-utf8 256)))
  (let
    ((photo (unwrap! (map-get? photos photo-id) (err err-not-found))))
    (asserts! (is-eq tx-sender (get owner photo)) (err err-unauthorized))
    (asserts! (> expires block-height) (err err-invalid-expiry))
    (ok (map-set licenses 
      { photo-id: photo-id, licensee: licensee }
      {
        granted-by: tx-sender,
        expires: expires,
        terms: terms
      }))
  )
)

(define-public (revoke-license
  (photo-id uint)
  (licensee principal))
  (let
    ((photo (unwrap! (map-get? photos photo-id) (err err-not-found))))
    (asserts! (is-eq tx-sender (get owner photo)) (err err-unauthorized))
    (ok (map-delete licenses { photo-id: photo-id, licensee: licensee }))
  )
)

;; Read only functions
(define-read-only (get-photo-details (photo-id uint))
  (ok (map-get? photos photo-id))
)

(define-read-only (get-license-details (photo-id uint) (licensee principal))
  (let
    ((license (map-get? licenses { photo-id: photo-id, licensee: licensee })))
    (asserts! (not (is-none license)) (err err-not-found))
    (asserts! (is-license-valid photo-id licensee) (err err-license-expired))
    (ok license)
  )
)

(define-read-only (check-license-validity (photo-id uint) (licensee principal))
  (ok (is-license-valid photo-id licensee))
)
