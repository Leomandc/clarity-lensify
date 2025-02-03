;; Lensify - Photography Copyright Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))

;; Define NFT
(define-non-fungible-token photo-copyright uint)

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
    (ok (map-set licenses 
      { photo-id: photo-id, licensee: licensee }
      {
        granted-by: tx-sender,
        expires: expires,
        terms: terms
      }))
  )
)

;; Read only functions
(define-read-only (get-photo-details (photo-id uint))
  (ok (map-get? photos photo-id))
)

(define-read-only (get-license-details (photo-id uint) (licensee principal))
  (ok (map-get? licenses { photo-id: photo-id, licensee: licensee }))
)
