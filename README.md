# FundFlow Protocol

**Next-Generation Decentralized Crowdfunding on Stacks Blockchain**

FundFlow revolutionizes crowdfunding by leveraging Bitcoin's security through the Stacks blockchain, creating a trustless ecosystem where innovation meets funding without intermediaries or geographical limitations.

## Overview

FundFlow is a comprehensive decentralized crowdfunding protocol that establishes intelligent campaign management, democratic governance through contributor voting, automated fund escrow, and guaranteed refund mechanisms. Projects can define flexible funding parameters while contributors maintain voting rights proportional to their investment, ensuring accountability and transparency throughout the entire funding lifecycle.

## Key Features

### 🔐 **Bitcoin-Secured Transactions**

- Leverages Stacks blockchain for Bitcoin-level security
- STX token economics for seamless transactions
- Automated escrow system protecting both creators and contributors

### 🗳️ **Democratic Governance**

- Weighted voting system based on contribution amounts
- Contributors can vote on fund release after campaign success
- Proportional voting power ensures fair representation

### 💰 **Automated Fund Management**

- Milestone-based fund distribution
- Automatic refund system for unsuccessful campaigns
- Platform fee collection with configurable rates

### 🚨 **Security & Emergency Controls**

- Emergency pause mechanisms for rapid response
- Anti-fraud measures and input validation
- Owner-controlled intervention capabilities

### 📈 **Scalable Architecture**

- Support for unlimited concurrent campaigns
- Efficient data structures for gas optimization
- Built-in platform sustainability through fee structure

## Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Campaign      │    │   Contribution  │    │   Voting        │
│   Creator       │    │   System        │    │   Mechanism     │
│                 │    │                 │    │                 │
│ • Create        │◄──►│ • Contribute    │◄──►│ • Vote          │
│ • Manage        │    │ • Track         │    │ • Validate      │
│ • Claim Funds   │    │ • Refund        │    │ • Tally         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Smart         │
                    │   Contract      │
                    │   Core          │
                    │                 │
                    │ • State Mgmt    │
                    │ • Validation    │
                    │ • Security      │
                    └─────────────────┘
```

### Contract Architecture

#### Core Data Structures

**1. Campaign Registry (`campaigns`)**

```clarity
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
  min-contribution: uint
}
```

**2. Contribution Tracking (`contributions`)**

```clarity
{
  amount: uint,
  refunded: bool,
  voting-power: uint
}
```

**3. Voting Records (`contributor-votes`)**

```clarity
{
  voted: bool,
  vote-for: bool
}
```

#### Function Categories

**📝 Campaign Management**

- `create-campaign` - Launch new crowdfunding campaigns
- `cancel-campaign` - Creator-initiated cancellation
- `emergency-pause-campaign` - Admin emergency intervention

**💸 Financial Operations**

- `contribute` - Secure STX contributions to campaigns
- `claim-funds` - Creator fund withdrawal with fee distribution
- `request-refund` - Automated refund for failed campaigns

**🗳️ Governance**

- `vote` - Weighted voting mechanism for fund release
- `get-vote-status` - Query voting participation

**👁️ Read-Only Queries**

- `get-campaign` - Retrieve campaign information
- `get-contribution` - Access contribution details
- `is-campaign-active` - Real-time status verification
- `is-campaign-successful` - Success status determination

## Data Flow

### Campaign Lifecycle

```
1. CREATE CAMPAIGN
   ├── Validate parameters
   ├── Set deadline & voting periods
   ├── Initialize with ACTIVE status
   └── Increment campaign counter

2. CONTRIBUTION PHASE
   ├── Validate campaign is active
   ├── Transfer STX to escrow
   ├── Update contribution records
   ├── Assign voting power (if enabled)
   └── Add to contributor list

3. CAMPAIGN COMPLETION
   ├── Automatic status update at deadline
   ├── SUCCESS: Goal met → Enable fund claiming
   └── FAILURE: Goal not met → Enable refunds

4. VOTING PHASE (if enabled)
   ├── Contributors vote on fund release
   ├── Weighted by contribution amount
   ├── Majority vote determines outcome
   └── Voting deadline enforced

5. FUND DISTRIBUTION
   ├── SUCCESS + APPROVED: Funds to creator (minus platform fee)
   ├── SUCCESS + REJECTED: Refunds available
   └── FAILURE: Automatic refund eligibility
```

### Security Model

#### Access Controls

- **Contract Owner**: Emergency powers, fee management
- **Campaign Creator**: Campaign management, fund claiming
- **Contributors**: Voting rights, refund requests

#### Validation Layers

1. **Input Validation**: String length, amount limits, parameter bounds
2. **State Validation**: Campaign status, timing constraints
3. **Authorization**: Sender verification, ownership checks
4. **Business Logic**: Goal achievement, voting requirements

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks Wallet](https://www.hiro.so/wallet) for mainnet interaction
- Node.js and npm for testing framework

### Installation

```bash
# Clone the repository
git clone https://github.com/timothy-sam/fund-flow.git
cd fund-flow

# Install dependencies
npm install

# Run tests
npm test

# Check contracts
clarinet check
```

### Basic Usage

#### Creating a Campaign

```clarity
(contract-call? .fund-flow create-campaign
  "My Innovation Project"
  "Revolutionary blockchain solution for decentralized finance"
  u1000000  ;; 1 STX goal
  u1440     ;; 10 days duration
  true      ;; Enable voting
  u720      ;; 5 days voting period
  u10000    ;; 0.01 STX minimum contribution
)
```

#### Contributing to a Campaign

```clarity
(contract-call? .fund-flow contribute
  u1        ;; Campaign ID
  u100000   ;; 0.1 STX contribution
)
```

#### Voting on Fund Release

```clarity
(contract-call? .fund-flow vote
  u1    ;; Campaign ID
  true  ;; Vote for fund release
)
```

## Configuration

### System Constants

- **Maximum Campaign Duration**: 144,000 blocks (~100 days)
- **Maximum Voting Duration**: 14,400 blocks (~10 days)
- **Minimum Campaign Duration**: 144 blocks (~1 day)
- **Default Platform Fee**: 2.5% (250/10000)
- **Maximum Contributors per Campaign**: 500

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | `ERR_UNAUTHORIZED` | Insufficient permissions |
| 101 | `ERR_CAMPAIGN_NOT_FOUND` | Invalid campaign ID |
| 102 | `ERR_CAMPAIGN_ENDED` | Campaign past deadline |
| 103 | `ERR_CAMPAIGN_ACTIVE` | Action requires inactive campaign |
| 104 | `ERR_GOAL_NOT_MET` | Funding goal not achieved |
| 105 | `ERR_ALREADY_REFUNDED` | Refund already processed |
| 106 | `ERR_NO_CONTRIBUTION` | No contribution found |
| 107 | `ERR_INVALID_AMOUNT` | Below minimum contribution |
| 108 | `ERR_INVALID_PARAMETERS` | Invalid input parameters |
| 109 | `ERR_VOTING_PERIOD_ENDED` | Voting deadline passed |
| 110 | `ERR_ALREADY_VOTED` | Vote already cast |
| 111 | `ERR_INSUFFICIENT_VOTING_POWER` | No voting rights |
| 112 | `ERR_CONTRIBUTOR_LIST_FULL` | Maximum contributors reached |
| 113 | `ERR_INVALID_STRING` | String validation failed |

## Testing

Run the comprehensive test suite:

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Run specific test file
npm test -- fund-flow.test.ts
```

## Security Considerations

### Audit Status

⚠️ **This contract has not been audited.** Use at your own risk in production environments.

### Known Considerations

- **Re-entrancy Protection**: Contract uses STX transfers with proper state updates
- **Integer Overflow**: Clarity's built-in uint overflow protection
- **Access Control**: Multi-layer authorization system
- **Emergency Controls**: Admin pause functionality for crisis management

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [Stacks Blockchain](https://www.stacks.co/)
- Developed with [Clarinet](https://github.com/hirosystems/clarinet)
- Inspired by the vision of decentralized funding mechanisms
