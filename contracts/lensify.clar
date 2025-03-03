;; Lensify - Photography Copyright Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))
(define-constant err-invalid-expiry (err u104))
(define-constant err-license-expired (err u105))
(define-constant err-invalid-input (err u106))

;; Define NFT
(define-non-fungible-token photo-copyright uint)

;; Events
(impl-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.photo-event-trait.photo-event-trait)

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
  })

(define-map licenses 
  { photo-id: uint, licensee: principal }
  {
    granted-by: principal,
    expires: uint,
    terms: (string-utf8 256)
  })

;; Data variables
(define-data-var last-photo-id uint u0)

;; Helper functions
(define-private (is-license-valid (photo-id uint) (licensee principal))
  (match (map-get? licenses { photo-id: photo-id, licensee: licensee })
    license (> (get expires license) block-height)
    false
  ))

(define-private (validate-string (str (string-utf8 256)))
  (and 
    (not (is-eq str ""))
    (> (len str) u0)
  ))

(define-private (revoke-all-licenses (photo-id uint))
  (filter map-delete licenses
    (map-get? licenses { photo-id: photo-id })))

;; Public functions
(define-public (register-photo 
  (title (string-utf8 64))
  (description (string-utf8 256))
  (image-uri (string-utf8 256))
  (license-type (string-utf8 32)))
  (begin
    (asserts! (validate-string title) (err err-invalid-input))
    (asserts! (validate-string description) (err err-invalid-input))
    (asserts! (validate-string image-uri) (err err-invalid-input))
    (asserts! (validate-string license-type) (err err-invalid-input))
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
      (emit-photo-registered photo-id tx-sender title)
      (ok photo-id)
    )))

(define-public (transfer-copyright
  (photo-id uint)
  (recipient principal))
  (let
    ((photo (unwrap! (map-get? photos photo-id) (err err-not-found))))
    (asserts! (is-eq tx-sender (get owner photo)) (err err-unauthorized))
    (try! (nft-transfer? photo-copyright photo-id tx-sender recipient))
    (revoke-all-licenses photo-id)
    (emit-copyright-transferred photo-id tx-sender recipient)
    (ok (map-set photos photo-id
      (merge photo { owner: recipient })))
  ))

;; [Remaining functions stay the same with added event emissions]
