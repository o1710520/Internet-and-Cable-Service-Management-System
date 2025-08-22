;; Equipment Management Contract
;; Manages equipment rental, purchases, and streaming service integration

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-EQUIPMENT-NOT-FOUND (err u501))
(define-constant ERR-INSUFFICIENT-INVENTORY (err u502))
(define-constant ERR-RENTAL-NOT-FOUND (err u503))
(define-constant ERR-INVALID-EQUIPMENT-TYPE (err u504))

;; Data Variables
(define-data-var next-equipment-id uint u1)
(define-data-var next-rental-id uint u1)

;; Data Maps
(define-map equipment-catalog
  { equipment-id: uint }
  {
    name: (string-ascii 50),
    equipment-type: (string-ascii 20),
    model: (string-ascii 30),
    purchase-price: uint,
    rental-price: uint,
    inventory-count: uint,
    specifications: (string-ascii 200),
    compatible-services: (string-ascii 100),
    active: bool
  }
)

(define-map equipment-rentals
  { rental-id: uint }
  {
    customer: principal,
    equipment-id: uint,
    rental-start: uint,
    rental-end: (optional uint),
    monthly-fee: uint,
    deposit: uint,
    status: (string-ascii 15),
    installation-address: (string-ascii 100)
  }
)

(define-map customer-equipment
  { customer: principal }
  { rental-ids: (list 20 uint), owned-equipment: (list 20 uint) }
)

(define-map streaming-bundles
  { bundle-id: uint }
  {
    name: (string-ascii 50),
    services: (string-ascii 200),
    monthly-price: uint,
    equipment-required: (list 5 uint),
    active: bool
  }
)

(define-map customer-bundles
  { customer: principal }
  { active-bundles: (list 10 uint) }
)

;; Private Functions
(define-private (is-valid-equipment-type (equipment-type (string-ascii 20)))
  (or
    (is-eq equipment-type "modem")
    (is-eq equipment-type "router")
    (is-eq equipment-type "cable-box")
    (is-eq equipment-type "streaming-device")
    (is-eq equipment-type "dvr")
  )
)

(define-private (has-sufficient-inventory (equipment-id uint))
  (match (map-get? equipment-catalog { equipment-id: equipment-id })
    equipment (> (get inventory-count equipment) u0)
    false
  )
)

;; Public Functions
(define-public (add-equipment-to-catalog
  (name (string-ascii 50))
  (equipment-type (string-ascii 20))
  (model (string-ascii 30))
  (purchase-price uint)
  (rental-price uint)
  (inventory-count uint)
  (specifications (string-ascii 200))
  (compatible-services (string-ascii 100))
)
  (let
    (
      (equipment-id (var-get next-equipment-id))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-equipment-type equipment-type) ERR-INVALID-EQUIPMENT-TYPE)

    (map-set equipment-catalog
      { equipment-id: equipment-id }
      {
        name: name,
        equipment-type: equipment-type,
        model: model,
        purchase-price: purchase-price,
        rental-price: rental-price,
        inventory-count: inventory-count,
        specifications: specifications,
        compatible-services: compatible-services,
        active: true
      }
    )

    (var-set next-equipment-id (+ equipment-id u1))

    (ok equipment-id)
  )
)

(define-public (rent-equipment
  (equipment-id uint)
  (installation-address (string-ascii 100))
)
  (let
    (
      (equipment (unwrap! (map-get? equipment-catalog { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (rental-id (var-get next-rental-id))
      (customer tx-sender)
    )
    (asserts! (get active equipment) ERR-EQUIPMENT-NOT-FOUND)
    (asserts! (has-sufficient-inventory equipment-id) ERR-INSUFFICIENT-INVENTORY)

    ;; Create rental record
    (map-set equipment-rentals
      { rental-id: rental-id }
      {
        customer: customer,
        equipment-id: equipment-id,
        rental-start: block-height,
        rental-end: none,
        monthly-fee: (get rental-price equipment),
        deposit: (get rental-price equipment), ;; Deposit equals one month rent
        status: "active",
        installation-address: installation-address
      }
    )

    ;; Update inventory
    (map-set equipment-catalog
      { equipment-id: equipment-id }
      (merge equipment { inventory-count: (- (get inventory-count equipment) u1) })
    )

    ;; Update customer equipment list
    (let
      (
        (current-equipment (default-to { rental-ids: (list), owned-equipment: (list) }
          (map-get? customer-equipment { customer: customer })))
        (updated-rentals (unwrap-panic
          (as-max-len? (append (get rental-ids current-equipment) rental-id) u20)))
      )
      (map-set customer-equipment
        { customer: customer }
        (merge current-equipment { rental-ids: updated-rentals })
      )
    )

    (var-set next-rental-id (+ rental-id u1))

    (ok rental-id)
  )
)

(define-public (return-equipment (rental-id uint))
  (let
    (
      (rental (unwrap! (map-get? equipment-rentals { rental-id: rental-id }) ERR-RENTAL-NOT-FOUND))
      (equipment (unwrap-panic (map-get? equipment-catalog { equipment-id: (get equipment-id rental) })))
    )
    (asserts! (is-eq tx-sender (get customer rental)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status rental) "active") ERR-RENTAL-NOT-FOUND)

    ;; Update rental status
    (map-set equipment-rentals
      { rental-id: rental-id }
      (merge rental { status: "returned", rental-end: (some block-height) })
    )

    ;; Return to inventory
    (map-set equipment-catalog
      { equipment-id: (get equipment-id rental) }
      (merge equipment { inventory-count: (+ (get inventory-count equipment) u1) })
    )

    (ok true)
  )
)

(define-public (purchase-equipment (equipment-id uint) (installation-address (string-ascii 100)))
  (let
    (
      (equipment (unwrap! (map-get? equipment-catalog { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (customer tx-sender)
    )
    (asserts! (get active equipment) ERR-EQUIPMENT-NOT-FOUND)
    (asserts! (has-sufficient-inventory equipment-id) ERR-INSUFFICIENT-INVENTORY)

    ;; Update inventory
    (map-set equipment-catalog
      { equipment-id: equipment-id }
      (merge equipment { inventory-count: (- (get inventory-count equipment) u1) })
    )

    ;; Update customer owned equipment
    (let
      (
        (current-equipment (default-to { rental-ids: (list), owned-equipment: (list) }
          (map-get? customer-equipment { customer: customer })))
        (updated-owned (unwrap-panic
          (as-max-len? (append (get owned-equipment current-equipment) equipment-id) u20)))
      )
      (map-set customer-equipment
        { customer: customer }
        (merge current-equipment { owned-equipment: updated-owned })
      )
    )

    (ok true)
  )
)

(define-public (create-streaming-bundle
  (name (string-ascii 50))
  (services (string-ascii 200))
  (monthly-price uint)
  (equipment-required (list 5 uint))
)
  (let
    (
      (bundle-id (var-get next-equipment-id)) ;; Reusing counter for simplicity
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set streaming-bundles
      { bundle-id: bundle-id }
      {
        name: name,
        services: services,
        monthly-price: monthly-price,
        equipment-required: equipment-required,
        active: true
      }
    )

    (var-set next-equipment-id (+ bundle-id u1))

    (ok bundle-id)
  )
)

(define-public (subscribe-to-bundle (bundle-id uint))
  (let
    (
      (bundle (unwrap! (map-get? streaming-bundles { bundle-id: bundle-id }) ERR-EQUIPMENT-NOT-FOUND))
      (customer tx-sender)
    )
    (asserts! (get active bundle) ERR-EQUIPMENT-NOT-FOUND)

    ;; Update customer bundles
    (let
      (
        (current-bundles (default-to { active-bundles: (list) }
          (map-get? customer-bundles { customer: customer })))
        (updated-bundles (unwrap-panic
          (as-max-len? (append (get active-bundles current-bundles) bundle-id) u10)))
      )
      (map-set customer-bundles
        { customer: customer }
        { active-bundles: updated-bundles }
      )
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment-catalog { equipment-id: equipment-id })
)

(define-read-only (get-rental (rental-id uint))
  (map-get? equipment-rentals { rental-id: rental-id })
)

(define-read-only (get-customer-equipment (customer principal))
  (map-get? customer-equipment { customer: customer })
)

(define-read-only (get-streaming-bundle (bundle-id uint))
  (map-get? streaming-bundles { bundle-id: bundle-id })
)

(define-read-only (get-customer-bundles (customer principal))
  (map-get? customer-bundles { customer: customer })
)

(define-read-only (get-next-equipment-id)
  (var-get next-equipment-id)
)

(define-read-only (get-next-rental-id)
  (var-get next-rental-id)
)
