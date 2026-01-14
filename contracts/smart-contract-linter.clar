(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u403))

(define-constant CONTRACT-OWNER tx-sender)

(define-constant REPUTATION-NOVICE u0)
(define-constant REPUTATION-APPRENTICE u100)
(define-constant REPUTATION-DEVELOPER u500)
(define-constant REPUTATION-EXPERT u1500)
(define-constant REPUTATION-MASTER u3000)

(define-constant LEADERBOARD-SIZE u10)

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

(define-map developer-reputation
    { developer: principal }
    {
        total-reputation: uint,
        reputation-level: (string-ascii 20),
        badges-earned: uint,
        streak-count: uint,
        last-activity: uint,
        quality-bonus: uint,
        community-endorsements: uint
    }
)

(define-map reputation-leaderboard
    { rank: uint }
    { developer: (optional principal), reputation-points: uint }
)

(define-map developer-badges
    { developer: principal, badge-type: (string-ascii 30) }
    { earned-at: uint, badge-level: uint }
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

(define-private (get-reputation-level (total-reputation uint))
    (if (>= total-reputation REPUTATION-MASTER) "MASTER"
    (if (>= total-reputation REPUTATION-EXPERT) "EXPERT"
    (if (>= total-reputation REPUTATION-DEVELOPER) "DEVELOPER"
    (if (>= total-reputation REPUTATION-APPRENTICE) "APPRENTICE"
    "NOVICE"))))
)

(define-private (leaderboard-empty-entry)
    { developer: none, reputation-points: u0 }
)

(define-private (get-leaderboard-entry (rank uint))
    (default-to (leaderboard-empty-entry) (map-get? reputation-leaderboard { rank: rank }))
)

(define-private (should-place-leaderboard-entry
    (entry { developer: (optional principal), reputation-points: uint })
    (points uint))
    (or (is-eq (get developer entry) none) (> points (get reputation-points entry)))
)

(define-private (clear-developer-from-leaderboard (developer principal))
    (begin
        (if (is-eq (get developer (get-leaderboard-entry u1)) (some developer))
            (map-delete reputation-leaderboard { rank: u1 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u2)) (some developer))
            (map-delete reputation-leaderboard { rank: u2 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u3)) (some developer))
            (map-delete reputation-leaderboard { rank: u3 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u4)) (some developer))
            (map-delete reputation-leaderboard { rank: u4 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u5)) (some developer))
            (map-delete reputation-leaderboard { rank: u5 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u6)) (some developer))
            (map-delete reputation-leaderboard { rank: u6 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u7)) (some developer))
            (map-delete reputation-leaderboard { rank: u7 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u8)) (some developer))
            (map-delete reputation-leaderboard { rank: u8 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u9)) (some developer))
            (map-delete reputation-leaderboard { rank: u9 })
            true)
        (if (is-eq (get developer (get-leaderboard-entry u10)) (some developer))
            (map-delete reputation-leaderboard { rank: u10 })
            true)
        true
    )
)

(define-private (update-reputation-leaderboard (developer principal) (points uint))
    (begin
        (clear-developer-from-leaderboard developer)
        (let (
            (r1 (get-leaderboard-entry u1))
            (r2 (get-leaderboard-entry u2))
            (r3 (get-leaderboard-entry u3))
            (r4 (get-leaderboard-entry u4))
            (r5 (get-leaderboard-entry u5))
            (r6 (get-leaderboard-entry u6))
            (r7 (get-leaderboard-entry u7))
            (r8 (get-leaderboard-entry u8))
            (r9 (get-leaderboard-entry u9))
            (r10 (get-leaderboard-entry u10))
        )
        (if (should-place-leaderboard-entry r1 points)
            (begin
                (map-set reputation-leaderboard { rank: u10 } r9)
                (map-set reputation-leaderboard { rank: u9 } r8)
                (map-set reputation-leaderboard { rank: u8 } r7)
                (map-set reputation-leaderboard { rank: u7 } r6)
                (map-set reputation-leaderboard { rank: u6 } r5)
                (map-set reputation-leaderboard { rank: u5 } r4)
                (map-set reputation-leaderboard { rank: u4 } r3)
                (map-set reputation-leaderboard { rank: u3 } r2)
                (map-set reputation-leaderboard { rank: u2 } r1)
                (map-set reputation-leaderboard { rank: u1 } { developer: (some developer), reputation-points: points })
                true
            )
            (if (should-place-leaderboard-entry r2 points)
                (begin
                    (map-set reputation-leaderboard { rank: u10 } r9)
                    (map-set reputation-leaderboard { rank: u9 } r8)
                    (map-set reputation-leaderboard { rank: u8 } r7)
                    (map-set reputation-leaderboard { rank: u7 } r6)
                    (map-set reputation-leaderboard { rank: u6 } r5)
                    (map-set reputation-leaderboard { rank: u5 } r4)
                    (map-set reputation-leaderboard { rank: u4 } r3)
                    (map-set reputation-leaderboard { rank: u3 } r2)
                    (map-set reputation-leaderboard { rank: u2 } { developer: (some developer), reputation-points: points })
                    true
                )
                (if (should-place-leaderboard-entry r3 points)
                    (begin
                        (map-set reputation-leaderboard { rank: u10 } r9)
                        (map-set reputation-leaderboard { rank: u9 } r8)
                        (map-set reputation-leaderboard { rank: u8 } r7)
                        (map-set reputation-leaderboard { rank: u7 } r6)
                        (map-set reputation-leaderboard { rank: u6 } r5)
                        (map-set reputation-leaderboard { rank: u5 } r4)
                        (map-set reputation-leaderboard { rank: u4 } r3)
                        (map-set reputation-leaderboard { rank: u3 } { developer: (some developer), reputation-points: points })
                        true
                    )
                    (if (should-place-leaderboard-entry r4 points)
                        (begin
                            (map-set reputation-leaderboard { rank: u10 } r9)
                            (map-set reputation-leaderboard { rank: u9 } r8)
                            (map-set reputation-leaderboard { rank: u8 } r7)
                            (map-set reputation-leaderboard { rank: u7 } r6)
                            (map-set reputation-leaderboard { rank: u6 } r5)
                            (map-set reputation-leaderboard { rank: u5 } r4)
                            (map-set reputation-leaderboard { rank: u4 } { developer: (some developer), reputation-points: points })
                            true
                        )
                        (if (should-place-leaderboard-entry r5 points)
                            (begin
                                (map-set reputation-leaderboard { rank: u10 } r9)
                                (map-set reputation-leaderboard { rank: u9 } r8)
                                (map-set reputation-leaderboard { rank: u8 } r7)
                                (map-set reputation-leaderboard { rank: u7 } r6)
                                (map-set reputation-leaderboard { rank: u6 } r5)
                                (map-set reputation-leaderboard { rank: u5 } { developer: (some developer), reputation-points: points })
                                true
                            )
                            (if (should-place-leaderboard-entry r6 points)
                                (begin
                                    (map-set reputation-leaderboard { rank: u10 } r9)
                                    (map-set reputation-leaderboard { rank: u9 } r8)
                                    (map-set reputation-leaderboard { rank: u8 } r7)
                                    (map-set reputation-leaderboard { rank: u7 } r6)
                                    (map-set reputation-leaderboard { rank: u6 } { developer: (some developer), reputation-points: points })
                                    true
                                )
                                (if (should-place-leaderboard-entry r7 points)
                                    (begin
                                        (map-set reputation-leaderboard { rank: u10 } r9)
                                        (map-set reputation-leaderboard { rank: u9 } r8)
                                        (map-set reputation-leaderboard { rank: u8 } r7)
                                        (map-set reputation-leaderboard { rank: u7 } { developer: (some developer), reputation-points: points })
                                        true
                                    )
                                    (if (should-place-leaderboard-entry r8 points)
                                        (begin
                                            (map-set reputation-leaderboard { rank: u10 } r9)
                                            (map-set reputation-leaderboard { rank: u9 } r8)
                                            (map-set reputation-leaderboard { rank: u8 } { developer: (some developer), reputation-points: points })
                                            true
                                        )
                                        (if (should-place-leaderboard-entry r9 points)
                                            (begin
                                                (map-set reputation-leaderboard { rank: u10 } r9)
                                                (map-set reputation-leaderboard { rank: u9 } { developer: (some developer), reputation-points: points })
                                                true
                                            )
                                            (if (should-place-leaderboard-entry r10 points)
                                                (begin
                                                    (map-set reputation-leaderboard { rank: u10 } { developer: (some developer), reputation-points: points })
                                                    true
                                                )
                                                true
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        ))
    )
)

(define-private (calculate-reputation-points (quality-score uint) (streak-bonus uint))
    (let (
        (base-points (if (>= quality-score u90) u50
                     (if (>= quality-score u70) u30
                     (if (>= quality-score u50) u15
                     u5))))
        (streak-multiplier (if (> streak-bonus u5) u2 u1))
    )
    (* base-points streak-multiplier)
    )
)

(define-private (award-badge (developer principal) (badge-type (string-ascii 30)) (level uint))
    (map-set developer-badges 
        { developer: developer, badge-type: badge-type } 
        { earned-at: stacks-block-height, badge-level: level }
    )
)

(define-private (check-and-award-badges (developer principal) (quality-score uint) (streak-count uint))
    (begin
        (if (>= quality-score u95)
            (award-badge developer "PERFECTIONIST" u1)
            true)
        (if (>= streak-count u10)
            (award-badge developer "CONSISTENCY_MASTER" u1)
            true)
        (if (>= streak-count u25)
            (award-badge developer "DEDICATION_LEGEND" u1)
            true)
        true
    )
)

(define-private (update-reputation-system (developer principal) (quality-score uint))
    (let (
        (current-rep (default-to 
            { total-reputation: u0, reputation-level: "NOVICE", badges-earned: u0, 
              streak-count: u0, last-activity: u0, quality-bonus: u0, community-endorsements: u0 }
            (map-get? developer-reputation { developer: developer })
        ))
        (streak-bonus (if (< (- stacks-block-height (get last-activity current-rep)) u1000) 
                         (+ (get streak-count current-rep) u1) u1))
        (reputation-gained (calculate-reputation-points quality-score streak-bonus))
        (new-total-rep (+ (get total-reputation current-rep) reputation-gained))
        (new-level (get-reputation-level new-total-rep))
        (quality-bonus (if (>= quality-score u80) (+ (get quality-bonus current-rep) u10) 
                                                  (get quality-bonus current-rep)))
    )
    (begin
        (map-set developer-reputation { developer: developer } {
            total-reputation: new-total-rep,
            reputation-level: new-level,
            badges-earned: (get badges-earned current-rep),
            streak-count: streak-bonus,
            last-activity: stacks-block-height,
            quality-bonus: quality-bonus,
            community-endorsements: (get community-endorsements current-rep)
        })
        (check-and-award-badges developer quality-score streak-bonus)
        (update-reputation-leaderboard developer new-total-rep)
        new-total-rep
    ))
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
        (update-reputation-system tx-sender quality-score)
        
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

(define-public (set-quality-threshold (level (string-ascii 20)) (min-score uint) (max-score uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (<= min-score max-score) ERR-INVALID-INPUT)
        (asserts! (<= max-score u100) ERR-INVALID-INPUT)
        (asserts! (>= min-score u0) ERR-INVALID-INPUT)
        (map-set quality-thresholds { level: level } { min-score: min-score, max-score: max-score })
        (ok true)
    )
)

(define-read-only (get-quality-threshold (level (string-ascii 20)))
    (map-get? quality-thresholds { level: level })
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

(define-public (endorse-developer (developer principal))
    (let (
        (current-rep (default-to
            { total-reputation: u0, reputation-level: "NOVICE", badges-earned: u0,
              streak-count: u0, last-activity: u0, quality-bonus: u0, community-endorsements: u0 }
            (map-get? developer-reputation { developer: developer })
        ))
        (endorser-rep (map-get? developer-reputation { developer: tx-sender }))
    )
    (begin
        (asserts! (not (is-eq tx-sender developer)) ERR-INVALID-INPUT)
        (asserts! (is-some endorser-rep) ERR-NOT-FOUND)
        (asserts! (>= (get total-reputation (unwrap-panic endorser-rep)) REPUTATION-DEVELOPER) ERR-INSUFFICIENT-REPUTATION)

        (let (
            (new-total (+ (get total-reputation current-rep) u25))
            (new-endorsements (+ (get community-endorsements current-rep) u1))
            (new-level (get-reputation-level new-total))
        )
        (begin
            (map-set developer-reputation { developer: developer }
                (merge current-rep {
                    community-endorsements: new-endorsements,
                    total-reputation: new-total,
                    reputation-level: new-level
                }))
            (update-reputation-leaderboard developer new-total)
            (ok true)
        ))
    ))
)

(define-read-only (get-developer-reputation (developer principal))
    (map-get? developer-reputation { developer: developer })
)

(define-read-only (get-developer-badges (developer principal) (badge-type (string-ascii 30)))
    (map-get? developer-badges { developer: developer, badge-type: badge-type })
)

(define-read-only (get-reputation-leaderboard (start-rank uint) (count uint))
    (begin
        (asserts! (is-eq start-rank u1) ERR-INVALID-INPUT)
        (asserts! (is-eq count LEADERBOARD-SIZE) ERR-INVALID-INPUT)
        (ok (list
            (merge { rank: u1 } (get-leaderboard-entry u1))
            (merge { rank: u2 } (get-leaderboard-entry u2))
            (merge { rank: u3 } (get-leaderboard-entry u3))
            (merge { rank: u4 } (get-leaderboard-entry u4))
            (merge { rank: u5 } (get-leaderboard-entry u5))
            (merge { rank: u6 } (get-leaderboard-entry u6))
            (merge { rank: u7 } (get-leaderboard-entry u7))
            (merge { rank: u8 } (get-leaderboard-entry u8))
            (merge { rank: u9 } (get-leaderboard-entry u9))
            (merge { rank: u10 } (get-leaderboard-entry u10))
        ))
    )
)

(define-read-only (get-developer-leaderboard-rank (developer principal))
    (ok
        (if (is-eq (get developer (get-leaderboard-entry u1)) (some developer)) (some u1)
        (if (is-eq (get developer (get-leaderboard-entry u2)) (some developer)) (some u2)
        (if (is-eq (get developer (get-leaderboard-entry u3)) (some developer)) (some u3)
        (if (is-eq (get developer (get-leaderboard-entry u4)) (some developer)) (some u4)
        (if (is-eq (get developer (get-leaderboard-entry u5)) (some developer)) (some u5)
        (if (is-eq (get developer (get-leaderboard-entry u6)) (some developer)) (some u6)
        (if (is-eq (get developer (get-leaderboard-entry u7)) (some developer)) (some u7)
        (if (is-eq (get developer (get-leaderboard-entry u8)) (some developer)) (some u8)
        (if (is-eq (get developer (get-leaderboard-entry u9)) (some developer)) (some u9)
        (if (is-eq (get developer (get-leaderboard-entry u10)) (some developer)) (some u10)
        none)))))))))))
)

(define-read-only (get-leaderboard-entry-at-rank (rank uint))
    (begin
        (asserts! (>= rank u1) ERR-INVALID-INPUT)
        (asserts! (<= rank LEADERBOARD-SIZE) ERR-INVALID-INPUT)
        (ok (get-leaderboard-entry rank))
    )
)

(define-public (claim-reputation-reward)
    (let (
        (developer-rep (map-get? developer-reputation { developer: tx-sender }))
    )
    (match developer-rep
        rep-data (begin
            (asserts! (>= (get total-reputation rep-data) REPUTATION-EXPERT) ERR-INSUFFICIENT-REPUTATION)
            (ok "REWARD_CLAIMED")
        )
        ERR-NOT-FOUND
    ))
)

(define-read-only (estimate-reputation-gain (quality-score uint))
    (let (
        (current-rep (default-to 
            { total-reputation: u0, reputation-level: "NOVICE", badges-earned: u0, 
              streak-count: u0, last-activity: u0, quality-bonus: u0, community-endorsements: u0 }
            (map-get? developer-reputation { developer: tx-sender })
        ))
        (estimated-streak (+ (get streak-count current-rep) u1))
        (points-gained (calculate-reputation-points quality-score estimated-streak))
    )
    (ok {
        current-reputation: (get total-reputation current-rep),
        points-to-gain: points-gained,
        new-total: (+ (get total-reputation current-rep) points-gained),
        current-level: (get reputation-level current-rep),
        potential-level: (get-reputation-level (+ (get total-reputation current-rep) points-gained))
    })
    )
)

(define-read-only (get-reputation-requirements)
    (ok {
        novice: REPUTATION-NOVICE,
        apprentice: REPUTATION-APPRENTICE,
        developer: REPUTATION-DEVELOPER,
        expert: REPUTATION-EXPERT,
        master: REPUTATION-MASTER
    })
)

(begin (init-quality-thresholds))
