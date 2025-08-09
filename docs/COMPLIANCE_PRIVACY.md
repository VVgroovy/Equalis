### Compliance, Privacy, and Safety-by-Design

This protocol is designed for global, opt-in adoption by employers and individuals while respecting privacy and local regulations.

Principles:

- Privacy by default: No PII on-chain. Use verifiable credentials; only pseudonymous `identityId` hashes are anchored.
- User consent: Eligibility and identity binding require explicit opt-in.
- Compliance hooks: Integrations for sanctions screening and jurisdictional restrictions in the attestation service layer.
- Transparency: On-chain redirection and distributions are auditable without revealing identities.

Operational guidelines:

- Attesters must follow KYC/AML as required in their jurisdictions and attest only after lawful verification.
- Sanctions and watchlists should be enforced off-chain prior to registry updates.
- The protocol code is neutral; operators (employers, attesters) are responsible for local compliance.

Future enhancements:

- Selective disclosure with zk proofs (age, uniqueness, residency) without leaking identity.
- Decentralized attester set with slashing for fraudulent attestations.


