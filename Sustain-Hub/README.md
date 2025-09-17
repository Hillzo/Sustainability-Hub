# Impact Sustainability Tracking Smart Contract

## Overview

The Impact Sustainability Tracking Smart Contract is a comprehensive blockchain-based system designed to track, verify, and incentivize environmental and social impact initiatives. Built on the Stacks blockchain using Clarity, this contract enables organizations and individuals to create sustainability projects, report impact metrics, and maintain transparent accountability through a decentralized verification system.

## Features

### Core Functionality
- **Project Creation**: Register sustainability projects with specific impact targets and categories
- **Impact Tracking**: Submit detailed impact records with evidence and verification
- **Stakeholder Management**: Allow multiple stakeholders to participate and stake in projects
- **Milestone System**: Set and track achievement milestones with rewards
- **Verification Network**: Decentralized verifier system for impact validation
- **Reputation System**: Track verifier performance and reliability

### Impact Categories
1. Carbon Reduction
2. Renewable Energy
3. Waste Reduction
4. Water Conservation
5. Biodiversity
6. Social Impact

## Contract Structure

### Data Variables
- `contract-active`: Global contract status
- `total-projects`: Counter for total projects created
- `verification-fee`: Fee required for verifier registration (default: 1 STX)
- `min-stake-amount`: Minimum stake required for project creation (default: 5 STX)

### Key Data Maps
- `projects`: Core project information and status
- `impact-records`: Detailed impact submissions with evidence
- `verifiers`: Registered verifier network with reputation scores
- `stakeholder-balances`: Tracking of stakeholder investments
- `project-milestones`: Achievement targets and rewards

## Installation and Deployment

### Prerequisites
- Stacks blockchain testnet or mainnet access
- Clarinet development environment (for testing)
- STX tokens for deployment and transactions

### Deployment Steps
1. Clone or download the contract file
2. Deploy using Clarinet or Stacks CLI
3. Initialize contract with desired parameters
4. Register initial verifiers

```bash
clarinet deploy --network testnet
```

## Usage Guide

### For Project Creators

#### Creating a Project
```clarity
(create-project 
  "Solar Panel Installation"     ;; name
  "Installing solar panels..."    ;; description
  u2                             ;; category (renewable energy)
  u1000                          ;; target impact
  u52560                         ;; duration in blocks (~1 year)
  u5000000)                      ;; stake amount (5 STX)
```

#### Adding Milestones
```clarity
(add-milestone 
  u1                             ;; project-id
  "50% completion target"        ;; description
  u500                           ;; target value
  u1000000)                      ;; reward amount (1 STX)
```

#### Submitting Impact Records
```clarity
(submit-impact-record
  u1                             ;; project-id
  u100                           ;; impact value
  "hash123...")                  ;; evidence hash
```

### For Stakeholders

#### Joining a Project
```clarity
(add-stakeholder u1 u2000000)    ;; project-id, stake amount (2 STX)
```

### For Verifiers

#### Registering as Verifier
```clarity
(register-verifier)              ;; Pay registration fee and join network
```

#### Verifying Impact Records
```clarity
(verify-impact-record u1 u1 true) ;; project-id, record-id, approved
```

## API Reference

### Public Functions

#### Administrative Functions
- `update-verification-fee(new-fee)`: Update verifier registration fee
- `update-min-stake-amount(new-amount)`: Update minimum stake requirement
- `toggle-contract-active()`: Enable/disable contract operations

#### Project Management
- `create-project(name, description, category, target-impact, duration-blocks, stake-amount)`: Create new project
- `add-stakeholder(project-id, stake-amount)`: Join project as stakeholder

#### Impact Reporting
- `submit-impact-record(project-id, impact-value, evidence-hash)`: Submit impact data
- `verify-impact-record(project-id, record-id, approved)`: Verify submitted records

#### Verification System
- `register-verifier()`: Join verifier network
- `check-milestone-achievement(project-id, milestone-id)`: Check and claim milestone rewards

#### Milestone Management
- `add-milestone(project-id, description, target-value, reward-amount)`: Add project milestone

### Read-Only Functions

#### Data Retrieval
- `get-project(project-id)`: Retrieve project details
- `get-impact-record(project-id, record-id)`: Get specific impact record
- `get-verifier(verifier)`: Get verifier information and reputation
- `get-milestone(project-id, milestone-id)`: Retrieve milestone details
- `get-stakeholder-balance(stakeholder)`: Check stakeholder balance
- `get-contract-stats()`: Get overall contract statistics

#### Status Checks
- `is-project-active(project-id)`: Check if project is active and not expired
- `get-project-progress(project-id)`: Calculate completion percentage
- `get-project-record-count(project-id)`: Get number of impact records
- `get-project-milestone-count(project-id)`: Get number of milestones

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100  | ERR_UNAUTHORIZED | Insufficient permissions |
| 101  | ERR_NOT_FOUND | Resource not found |
| 102  | ERR_INVALID_INPUT | Invalid input parameters |
| 103  | ERR_ALREADY_EXISTS | Resource already exists |
| 104  | ERR_INVALID_PERIOD | Invalid time period |
| 105  | ERR_INSUFFICIENT_BALANCE | Insufficient funds |
| 106  | ERR_INVALID_VERIFICATION | Verification error |
| 107  | ERR_EXPIRED | Resource has expired |

## Security Considerations

### Input Validation
- All input parameters are validated for type, range, and format
- String inputs are checked for length and non-empty content
- Numerical inputs have defined maximum limits to prevent overflow

### Access Control
- Project owners have exclusive rights to add milestones
- Only registered verifiers can verify impact records
- Stakeholders must join projects before submitting records
- Contract owner has administrative privileges

### Economic Security
- Minimum stake amounts prevent spam projects
- Verification fees ensure serious verifier participation
- Milestone rewards incentivize accurate reporting
- Reputation system discourages malicious verification

## Limitations and Constraints

### Technical Limits
- Maximum 1,000,000 projects per contract instance
- Maximum 1,000,000 impact records per project
- Maximum 1,000 milestones per project
- String length limits for names and descriptions

### Economic Limits
- Maximum verification fee: 1,000 STX
- Maximum stake amount: 100,000 STX
- Maximum reward amount: 10,000 STX per milestone

## Testing

### Unit Tests
The contract should be tested with Clarinet using comprehensive test cases covering:
- Project creation and management
- Impact record submission and verification
- Stakeholder participation
- Milestone achievement
- Error conditions and edge cases

### Integration Tests
- End-to-end project lifecycle testing
- Multi-stakeholder scenarios
- Verifier network functionality
- Economic incentive mechanisms