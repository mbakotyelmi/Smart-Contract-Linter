(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))

(define-constant CONTRACT-OWNER tx-sender)

(define-data-var next-lint-id uint u1)
(define-data-var total-lints uint u0)

(define-map lint-results
    { lint-id: uint }
    {
        submitter: principal,
        contract-code: (string-ascii 2048),
        quality-score: uint,
        issues-found: uint,
        severity-high: uint,
        severity-medium: uint,
        severity-low: uint,
        timestamp: uint,
        status: (string-ascii 20)
    }
)

(define-map user-lint-history
    { user: principal }
    {
        total-lints: uint,
        avg-quality-score: uint,
        last-lint-id: uint,
        best-score: uint,
        improvement-trend: int
    }
)

(define-map lint-issues
    { lint-id: uint, issue-index: uint }
    {
        issue-type: (string-ascii 50),
        severity: (string-ascii 10),
        line-number: uint,
        description: (string-ascii 200)
    }
)

(define-map quality-thresholds
    { level: (string-ascii 20) }
    { min-score: uint, max-score: uint }
)

(define-private (init-quality-thresholds)
    (begin
        (map-set quality-thresholds { level: "EXCELLENT" } { min-score: u90, max-score: u100 })
        (map-set quality-thresholds { level: "GOOD" } { min-score: u70, max-score: u89 })
        (map-set quality-thresholds { level: "FAIR" } { min-score: u50, max-score: u69 })
        (map-set quality-thresholds { level: "POOR" } { min-score: u0, max-score: u49 })
        true
    )
)

(define-private (calculate-quality-score (code (string-ascii 2048)))
    (let (
        (code-length u100)
        (base-score u50)
        (length-bonus (if (and (> code-length u100) (< code-length u1500)) u30 u0))
        (complexity-penalty (if (> code-length u1800) u20 u0))
        (readability-bonus (if (and (> code-length u200) (< code-length u1200)) u20 u0))
    )
    (let (
        (total-score (+ base-score length-bonus readability-bonus))
        (final-score (if (>= total-score complexity-penalty) (- total-score complexity-penalty) u0))
    )
    (if (> final-score u100) u100 final-score))
    )
)

(define-private (detect-issues (code (string-ascii 2048)))
    (let (
        (code-length u100)
        (basic-issues (if (< code-length u50) u3 u1))
        (complexity-issues (if (> code-length u1500) u2 u0))
    )
    (+ basic-issues complexity-issues)
    )
)

(define-private (calculate-severity-counts (issues-count uint))
    (let (
        (high-severity (if (>= issues-count u4) u1 u0))
        (medium-severity (if (and (>= issues-count u2) (< issues-count u4)) u1 u0))
        (low-severity (if (and (>= issues-count u1) (< issues-count u2)) u1 u0))
    )
    { high: high-severity, medium: medium-severity, low: low-severity }
    )
)

(define-private (get-quality-level (score uint))
    (if (>= score u90) "EXCELLENT"
    (if (>= score u70) "GOOD"
    (if (>= score u50) "FAIR"
    "POOR")))
)

(define-private (update-user-history (user principal) (lint-id uint) (quality-score uint))
    (let (
        (current-history (default-to 
            { total-lints: u0, avg-quality-score: u0, last-lint-id: u0, best-score: u0, improvement-trend: 0 }
            (map-get? user-lint-history { user: user })
        ))
        (new-total (+ (get total-lints current-history) u1))
        (new-avg (/ (+ (* (get avg-quality-score current-history) (get total-lints current-history)) quality-score) new-total))
        (new-best (if (> quality-score (get best-score current-history)) quality-score (get best-score current-history)))
        (trend (if (> new-total u1) 
            (if (> quality-score (get avg-quality-score current-history)) 1 -1) 
            0))
    )
    (map-set user-lint-history { user: user } {
        total-lints: new-total,
        avg-quality-score: new-avg,
        last-lint-id: lint-id,
        best-score: new-best,
        improvement-trend: trend
    })
    )
)

(define-public (submit-contract-for-linting (contract-code (string-ascii 2048)))
    (let (
        (lint-id (var-get next-lint-id))
        (quality-score (calculate-quality-score contract-code))
        (issues-count (detect-issues contract-code))
        (severity-counts (calculate-severity-counts issues-count))
        (timestamp stacks-block-height)
    )
    (begin
        (asserts! (> (len contract-code) u0) ERR-INVALID-INPUT)
        (asserts! (< (len contract-code) u2049) ERR-INVALID-INPUT)
        
        (map-set lint-results { lint-id: lint-id } {
            submitter: tx-sender,
            contract-code: contract-code,
            quality-score: quality-score,
            issues-found: issues-count,
            severity-high: (get high severity-counts),
            severity-medium: (get medium severity-counts),
            severity-low: (get low severity-counts),
            timestamp: timestamp,
            status: "COMPLETED"
        })
        
        (update-user-history tx-sender lint-id quality-score)
        
        (var-set next-lint-id (+ lint-id u1))
        (var-set total-lints (+ (var-get total-lints) u1))
        
        (ok lint-id)
    ))
)

(define-public (add-lint-issue 
    (lint-id uint) 
    (issue-index uint) 
    (issue-type (string-ascii 50)) 
    (severity (string-ascii 10)) 
    (line-number uint) 
    (description (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? lint-results { lint-id: lint-id })) ERR-NOT-FOUND)
        
        (map-set lint-issues { lint-id: lint-id, issue-index: issue-index } {
            issue-type: issue-type,
            severity: severity,
            line-number: line-number,
            description: description
        })
        
        (ok true)
    )
)

(define-read-only (get-lint-result (lint-id uint))
    (map-get? lint-results { lint-id: lint-id })
)

(define-read-only (get-user-history (user principal))
    (map-get? user-lint-history { user: user })
)

(define-read-only (get-lint-issue (lint-id uint) (issue-index uint))
    (map-get? lint-issues { lint-id: lint-id, issue-index: issue-index })
)

(define-read-only (get-quality-level-for-score (score uint))
    (ok (get-quality-level score))
)

(define-read-only (get-platform-stats)
    (ok {
        total-lints: (var-get total-lints),
        next-lint-id: (var-get next-lint-id),
        current-block: stacks-block-height
    })
)

(define-read-only (get-user-ranking (user principal))
    (let (
        (user-data (map-get? user-lint-history { user: user }))
    )
    (match user-data
        data (ok {
            quality-level: (get-quality-level (get best-score data)),
            best-score: (get best-score data),
            total-contributions: (get total-lints data),
            improvement-trend: (get improvement-trend data)
        })
        ERR-NOT-FOUND
    ))
)

(define-public (batch-lint-contracts (contracts (list 5 (string-ascii 2048))))
    (let (
        (results (map submit-contract-for-linting contracts))
    )
    (ok results)
    )
)

(define-read-only (estimate-quality-score (code (string-ascii 2048)))
    (ok (calculate-quality-score code))
)

(define-public (update-lint-status (lint-id uint) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? lint-results { lint-id: lint-id })) ERR-NOT-FOUND)
        
        (let (
            (current-result (unwrap! (map-get? lint-results { lint-id: lint-id }) ERR-NOT-FOUND))
        )
        (map-set lint-results { lint-id: lint-id } 
            (merge current-result { status: new-status }))
        (ok true)
        )
    )
)

(begin (init-quality-thresholds))
