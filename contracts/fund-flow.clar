;; FundFlow Protocol: Next-Generation Decentralized Crowdfunding
;;
;; Summary:
;; FundFlow revolutionizes crowdfunding by leveraging Bitcoin's security through
;; Stacks blockchain, creating a trustless ecosystem where innovation meets funding
;; without intermediaries or geographical limitations.
;;
;; Description:
;; This protocol establishes a comprehensive crowdfunding infrastructure featuring
;; intelligent campaign management, democratic governance through contributor voting,
;; automated fund escrow, and guaranteed refund mechanisms. Projects can define
;; flexible funding parameters while contributors maintain voting rights proportional
;; to their investment, ensuring accountability and transparency throughout the
;; entire funding lifecycle. The system automatically handles success/failure states,
;; implements anti-fraud measures, and provides emergency controls for maximum
;; security and reliability.
;;
;; Key Innovations:
;; - Bitcoin-secured transactions with STX token economics
;; - Weighted voting system based on contribution amounts  
;; - Automated milestone-based fund distribution
;; - Emergency pause mechanisms for rapid response
;; - Scalable architecture supporting unlimited concurrent campaigns
;; - Built-in platform sustainability through configurable fee structure

;; SYSTEM CONSTANTS

;; Access Control
(define-constant CONTRACT_OWNER tx-sender)

;; Error Code Definitions
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u101))
(define-constant ERR_CAMPAIGN_ENDED (err u102))
(define-constant ERR_CAMPAIGN_ACTIVE (err u103))
(define-constant ERR_GOAL_NOT_MET (err u104))
(define-constant ERR_ALREADY_REFUNDED (err u105))
(define-constant ERR_NO_CONTRIBUTION (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))
(define-constant ERR_INVALID_PARAMETERS (err u108))
(define-constant ERR_VOTING_PERIOD_ENDED (err u109))
(define-constant ERR_ALREADY_VOTED (err u110))
(define-constant ERR_INSUFFICIENT_VOTING_POWER (err u111))
(define-constant ERR_CONTRIBUTOR_LIST_FULL (err u112))
(define-constant ERR_INVALID_STRING (err u113))

;; Campaign Status Definitions
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_SUCCESSFUL u2)
(define-constant STATUS_FAILED u3)
(define-constant STATUS_CANCELLED u4)

;; System Validation Limits
(define-constant MAX_DURATION_BLOCKS u144000) ;; ~100 days at 10 min blocks
(define-constant MAX_VOTING_DURATION_BLOCKS u14400) ;; ~10 days
(define-constant MIN_DURATION_BLOCKS u144) ;; ~1 day
(define-constant MAX_CAMPAIGN_ID u1000000) ;; Reasonable upper bound

;; GLOBAL STATE VARIABLES

(define-data-var campaign-counter uint u0)
(define-data-var platform-fee-rate uint u250) ;; 2.5% (250/10000)

;; DATA STRUCTURE DEFINITIONS

;; Primary Campaign Registry
(define-map campaigns
  { campaign-id: uint }
  {
    creator: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    goal: uint,
    raised: uint,
    deadline-height: uint,
    created-height: uint,
    status: uint,
    voting-enabled: bool,
    voting-deadline-height: uint,
    votes-for: uint,
    votes-against: uint,
    min-contribution: uint,
  }
)

;; Contribution Tracking System
(define-map contributions
  {
    campaign-id: uint,
    contributor: principal,
  }
  {
    amount: uint,
    refunded: bool,
    voting-power: uint,
  }
)

;; Democratic Voting Records
(define-map contributor-votes
  {
    campaign-id: uint,
    voter: principal,
  }
  {
    voted: bool,
    vote-for: bool,
  }
)

;; Campaign Participant Management
(define-map campaign-contributors
  { campaign-id: uint }
  { contributor-list: (list 500 principal) }
)

;; READ-ONLY INTERFACE FUNCTIONS

;; Retrieve comprehensive campaign information
(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

;; Access contributor-specific funding details
(define-read-only (get-contribution
    (campaign-id uint)
    (contributor principal)
  )
  (map-get? contributions {
    campaign-id: campaign-id,
    contributor: contributor,
  })
)

;; Query total platform campaign count
(define-read-only (get-campaign-count)
  (var-get campaign-counter)
)

;; Access current platform fee structure
(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

;; Verify campaign active status in real-time
(define-read-only (is-campaign-active (campaign-id uint))
  (match (get-campaign campaign-id)
    campaign (and
      (is-eq (get status campaign) STATUS_ACTIVE)
      (< stacks-block-height (get deadline-height campaign))
    )
    false
  )
)

;; Determine campaign funding success status
(define-read-only (is-campaign-successful (campaign-id uint))
  (match (get-campaign campaign-id)
    campaign (>= (get raised campaign) (get goal campaign))
    false
  )
)

;; Calculate platform fee for given amount
(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

;; Retrieve voting participation status
(define-read-only (get-vote-status
    (campaign-id uint)
    (voter principal)
  )
  (map-get? contributor-votes {
    campaign-id: campaign-id,
    voter: voter,
  })
)

;; INTERNAL UTILITY FUNCTIONS

;; Validate string inputs for security
(define-private (is-valid-string (input (string-ascii 256)))
  (let ((length (len input)))
    (and
      (> length u0)
      (<= length u256)
      true
    )
  )
)

;; Enforce campaign ID boundaries
(define-private (is-valid-campaign-id (campaign-id uint))
  (and
    (> campaign-id u0)
    (<= campaign-id MAX_CAMPAIGN_ID)
  )
)

;; Manage contributor list expansion
(define-private (add-contributor-to-list
    (campaign-id uint)
    (contributor principal)
  )
  (let ((current-list (default-to (list)
      (get contributor-list
        (map-get? campaign-contributors { campaign-id: campaign-id })
      ))))
    (if (< (len current-list) u500)
      (begin
        (map-set campaign-contributors { campaign-id: campaign-id } { contributor-list: (unwrap! (as-max-len? (append current-list contributor) u500)
          ERR_CONTRIBUTOR_LIST_FULL
        ) }
        )
        (ok true)
      )
      (ok true)
    )
  )
)