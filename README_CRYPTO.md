### Equalis Crypto Quickstart

Prereqs: Node 20+, pnpm/npm, Foundry or Hardhat runtime.

1) Install

```bash
pnpm install || npm install
```

2) Compile

```bash
npx hardhat compile
```

3) Local deploy (spawns mock token for demo)

```bash
npx hardhat run scripts/deploy.ts --network localhost
```

4) Next steps

- Point `token` to a production stablecoin on your target network
- Wire the attestation service to call `registerIdentity` and `grantEligibility`
- Onboard employers and grant them `EMPLOYER_ROLE`
- Route payroll via `fundAndPay`, monitor overflow deposits into the pool
- Trigger `distribute` weekly or plug into an automation service

See `docs/ARCHITECTURE.md` for a deep dive.


