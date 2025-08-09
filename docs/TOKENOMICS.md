### Tokenomics and Economic Design

- Salary medium: Use a reputable fiat-backed stablecoin as the salary/payment token to keep value stable. The contracts are token-agnostic.
- Overflow flow: Any compensation above the annual cap per identity is redirected to the `RedistributionPool`.
- Eligibility: Adults (18+) who opt in and pass uniqueness checks receive redistribution. Off-chain VCs grant eligibility; on-chain registry reflects the state.
- Cadence: Weekly (7d) by default; configurable to bi-monthly or monthly via parameters/governance.
- Governance token (EQT): Fixed supply at genesis or capped inflation (e.g., 2% annually) controlled by on-chain governance for treasury incentives such as attester rewards and gas sponsorship.
- Incentives: Employers adopting the protocol may receive governance rewards; attesters receive bounties for high-quality, fraud-free attestations.

Risks and mitigations:

- Sybil: Multi-attester model with reputation, cross-checks, and privacy-preserving dedup signals.
- Perverse incentives: Redistribution is unconditional and equal per eligible during an epoch to avoid means-testing privacy risks; can add opt-in need-weighting via off-chain proofs later.
- Market shocks: Treasury diversifies and can throttle distribution intervals temporarily via governance in emergencies.


