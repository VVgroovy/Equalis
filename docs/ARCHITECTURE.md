### Equalis: Redistributive Crypto Architecture

This document outlines a pragmatic, privacy-preserving design for a redistributive cryptocurrency aimed at capping compensation and redistributing overflow to verified adults who opt in.

Key properties:

- Identity and eligibility via verifiable credentials (off-chain) referenced on-chain by pseudonymous `identityId`
- Enforced cap-at-source payroll contracts redirect overflow to a redistribution pool
- Periodic fair redistribution with protection against gas exhaustion via pagination
- Governance token for parameter changes and treasury decisions
- Gasless UX via account abstraction/paymasters (off-chain component)

Components:

1) On-chain (Solidity)
- `EligibilityRegistry`: Maps `address -> identityId` and tracks addresses eligible for redistribution. Only trusted attesters can bind identities and grant/revoke eligibility. No PII stored on-chain.
- `CompensationLimiter`: Enforces an annual compensation cap per identityId. Stateless interfaces like `remainingAllowance` and stateful `consume` keep the logic simple and auditable.
- `RedistributivePayroll`: Employer-facing payroll that pulls funds, pays employees up to their remaining allowance, and routes overflow to the pool. Globally enforces caps through `CompensationLimiter`.
- `RedistributionPool`: Holds overflow and redistributes to eligible addresses in batches to avoid OOG. Interval gating (weekly/monthly) ensures predictable cadence.
- `GovernanceToken`: ERC20 governance for parameter updates (via timelocked governance contracts in a future iteration).

Governance & automation additions:

- `GovernanceToken` upgraded to `ERC20Votes` for on-chain voting.
- `EqualisGovernor` + `TimelockSetup` integrate a timelocked governance process.
- `AutomationDistributor` exposes a Chainlink Automation-compatible interface to trigger weekly distributions safely.
- `MerkleEpochDistributor` enables epoch-based claim distributions to scale to 10M+ addresses per epoch.

2) Off-chain services
- Identity attestation service: issues W3C Verifiable Credentials to adults; anchors only an `identityId` hash on-chain via `EligibilityRegistry`.
- Paymaster/AA service: sponsors gas for beneficiaries and onboarding flows. Integrates with ERC-4337 bundlers.
- Oracles and payroll adapters: connect to employers/payroll providers; submit salary payments to `RedistributivePayroll`.
- Risk and Sybil defense: deduplicates identities and monitors abuse using privacy-preserving signals.

3) Mobile wallet
- Light-client wallet with AA for gasless claims and settings
- Selective disclosure of credentials using ZK-friendly schemes (e.g., BBS+ or zk-SNARK circuits in future work)

Design choices and tradeoffs:

- Cap enforcement is opt-in by employers using the payroll contract. The protocol makes compliance transparent and auditable.
- Identity uniqueness is delegated to attesters and privacy-preserving VCs; on-chain only sees a hash to avoid PII leaks.
- Redistribution uses push in batches for simplicity; can be upgraded to a claim-based model with Merkle/bitmap proofs to scale to millions.
- Token choice: protocol can operate over a stable token to maintain purchasing power; governance token is separate.

Upgrade path:

- Move to claim-based distributions (Merkle airdrops per epoch) to scale to 10M+ recipients cheaply.
- Add zk circuits to prove age/uniqueness without revealing identity, and to prove cap compliance across multiple employers.
- Transition governance to timelocked, delegated voting with Tally/Snapshot integration.


