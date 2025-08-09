## Equalis — Capped Payroll with Automatic Redistribution

Equalis is a crypto infrastructure to cap annual compensation (default 20,000,000.00 payment-token units) and automatically redistribute the overflow to eligible adults who opt in.

- Verifiable on-chain contracts (capped payroll, redistribution pool, eligibility registry)
- Timelocked on-chain governance (ERC20Votes)
- Weekly automation (Chainlink-compatible)
- Massive scale via epoch-based Merkle claims
- Privacy by design: pseudonymous identities (hash), optional ZK checks for age/uniqueness

### Highlights
- Per-identity annual cap enforced at source (`CompensationLimiter` + `RedistributivePayroll`).
- Overflow redirected to `RedistributionPool`, equally redistributed in batches (weekly by default).
- `EligibilityRegistry`: attestation without on-chain PII; optional ZK verifier hook.
- Governance: `GovernanceToken (EQT)` + `EqualisGovernor` + `TimelockSetup`.
- Scale: `MerkleEpochDistributor` for tens of millions of recipients.

### Quick code glance

```solidity
// RedistributivePayroll
function fundAndPay(address employee, uint256 amount) external onlyRole(EMPLOYER_ROLE)
```

```solidity
// RedistributionPool
function distribute(uint256 maxRecipients) external
```

```solidity
// EligibilityRegistry
function registerIdentity(address subject, bytes32 identityId) external onlyRole(ATTESTER_ROLE)
```

See `contracts/` and `docs/` for details. A French version is available in `README.fr.md`.

### Install

```bash
pnpm install || npm install
npx hardhat compile
```

### Configuration (.env)
Copy `.env.example` to `.env`:

```
PAYMENT_TOKEN_ADDRESS= # Stablecoin address (e.g. USDC)
PAYMENT_TOKEN_DECIMALS=6
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
RPC_URL=http://127.0.0.1:8545
```

### Local deploy

```bash
npx hardhat node &
npx hardhat run scripts/deploy.ts --network localhost
```

By default a `MockStablecoin` is deployed locally and the annual cap is aligned with `PAYMENT_TOKEN_DECIMALS` (20,000,000.00).

### Testnet deploy (e.g., Sepolia)

```bash
export PAYMENT_TOKEN_ADDRESS=0x...   # production stablecoin
export PAYMENT_TOKEN_DECIMALS=6
npx hardhat run scripts/deploy.ts --network sepolia
```

### Attestation & employers (scripts)

```bash
export REGISTRY=0x...
export PAYROLL=0x...
export EMPLOYER=0xEmployer
export SUBJECT=0xEmployee
npx hardhat run scripts/admin.ts --network sepolia
```

### Weekly automation (Chainlink)
- Deploy `AutomationDistributor` and point an Upkeep at `performUpkeep(bytes)`.
- Params: `batchSize` (max recipients per call), `minInterval` (e.g., 7 days).

### Large-scale distribution (Merkle epochs)
1) Off-chain: compute allocations + Merkle root.
2) On-chain: fund contract and call `setEpochRoot(epochId, root, totalAllocated)`.
3) Beneficiaries claim via `claim(index, account, amount, proof)`.

### Governance
1) Deploy `GovernanceToken`, `TimelockSetup`, `EqualisGovernor`.
2) Transfer admin roles of core contracts to the timelock.
3) Govern cadence/fees/attesters via proposals (timelocked).

### Fee policy (optional ≤ 5%)
- If enabled, fee applies only to overflow being redistributed (never salaries), with a hard cap and a decreasing schedule decided by governance.

### “Lakshmi” AI copilot
- Observes on/off-chain, produces fairness reports, detects anomalies/Sybil, proposes parameter changes (validated by vote, never controls funds). See `docs/ARCHITECTURE.md` and `docs/COMPLIANCE_PRIVACY.md`.

### References
- `docs/ARCHITECTURE.md`: architecture
- `docs/TOKENOMICS.md`: economics
- `docs/COMPLIANCE_PRIVACY.md`: compliance & privacy
- `docs/ROADMAP.md`: roadmap

French docs: see `README.fr.md`, `docs/ARCHITECTURE.fr.md`, `docs/TOKENOMICS.fr.md`, `docs/COMPLIANCE_PRIVACY.fr.md`, `docs/ROADMAP.fr.md`.

### License
MIT



# Equalis – Prototype de Cryptomonnaie Répartitrice

## 0. Table of Contents
1. [Introduction](#introduction)  
2. [Prerequisites](#prerequisites)  
3. [Step‑by‑Step Environment Setup](#environment-setup)  
    1. [Scaffold the Equalis Blockchain](#scaffold)  
    2. [Add CosmWasm Support](#add-cosmwasm)  
    3. [Configure `$EQLS` as Native Token](#configure-token)  
    4. [Compile & Run the Local Chain](#run-chain)  
4. [Smart‑Contract Development – `EqualisRedistribute`](#smart-contract)  
5. [Deploying the Contract](#deploying)  
6. [LakshmiVault AI Automation (Off‑chain)](#ai)  
7. [Simulating the ZK Revenue Proof](#zk)  
8. [End‑to‑End CLI Tests](#tests)  
9. [Architecture Recap](#architecture)  
10. [Legal & Compliance Notes](#legal)  
11. [Conclusion & Next Steps](#conclusion)

---

<a name="introduction"></a>
## 1. Introduction

**Equalis** is an experimental crypto‑economic protocol that caps personal annual income at **€20 million** (“**20 millions max**”).  
Anything earned _above_ that threshold is _automatically and instantly_ redistributed to all adult humans on Earth through the native token **$EQLS**.

This MVP implements:

| Layer | Tech |
|-------|------|
| **Blockchain** | **Cosmos SDK** chain scaffolded with **Ignite CLI** |
| **Smart‑contracts** | **CosmWasm** (Rust → WebAssembly) |
| **Governance** | Off‑chain script nick‑named **LakshmiVault AI** acting as on‑chain admin |
| **Confidentiality** | Simulated **ZK‑proof** of income (real amount never published) |

The README contains every command & file path required to reproduce the prototype locally.

---

<a name="prerequisites"></a>
## 2. Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Go | ≥ 1.18 | build Cosmos SDK chain |
| **Ignite CLI** | ≥ 0.28 | chain scaffolding |
| Rust | stable | write CosmWasm contracts |
| Target `wasm32-unknown-unknown` | – | compile to WebAssembly |
| Docker | latest | optimise Wasm binaries (`cosmwasm/workspace-optimizer`) |
| A Unix‑like shell | bash/zsh | run commands |
| (Optional) Python 3 + CosmPy **or** Node 18 + CosmJS | – | scripting LakshmiVault AI |

### Quick install snippets

```bash
# Go
brew install go            # or wget https://go.dev/...
# Ignite CLI
curl https://get.ignite.com/cli! | bash
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown
# Docker (if not already)
brew install --cask docker  # macOS example
```

---

<a name="environment-setup"></a>
## 3. Step‑by‑Step Environment Setup

<a name="scaffold"></a>
### 3.1 Scaffold the Equalis Blockchain

```bash
ignite scaffold chain equalis --no-module
cd equalis
```

<a name="add-cosmwasm"></a>
### 3.2 Add CosmWasm Support

```bash
ignite app install -g github.com/ignite/apps/wasm
ignite wasm add           # inside ./equalis
```

<a name="configure-token"></a>
### 3.3 Configure `$EQLS` as Native Token

Edit **`config.yml`** or `app/app.go`:

```yaml
# staking / bank denom
staking:
  denom: "ueqls"   # 1 EQLS = 1 000 000 ueqls
```

Update all occurrences of default `stake`.

<a name="run-chain"></a>
### 3.4 Compile & Run the Local Chain

```bash
ignite chain serve
```

The CLI binary **`equalisd`** is generated. Keep this terminal open (blocks constantly produced).

Create accounts:

```bash
equalisd keys add richman
equalisd keys add user1
equalisd keys add user2
equalisd keys add LakshmiAI
# fund them from default 'alice'
equalisd tx bank send alice $(equalisd keys show richman -a) 25000000000000ueqls -y
equalisd tx bank send alice $(equalisd keys show user1 -a)   100000000000ueqls  -y
equalisd tx bank send alice $(equalisd keys show user2 -a)   100000000000ueqls  -y
equalisd tx bank send alice $(equalisd keys show LakshmiAI -a) 1000000ueqls -y
```

---

<a name="smart-contract"></a>
## 4. Smart‑Contract Development – `EqualisRedistribute`

Initialise template:

```bash
cargo generate --git https://github.com/CosmWasm/cw-template.git --name equalis_redistribute
cd equalis_redistribute
```

Key message/state skeleton (simplified):

```rust
// msg.rs
pub struct InstantiateMsg {
    pub beneficiaries: Vec<String>,
    pub threshold: Uint128,           // in ueqls
}

#[derive(Clone)]
pub enum ExecuteMsg {
    Contribute {},                    // attach funds
    Distribute {},                    // admin‑only
    UpdateThreshold { new_threshold: Uint128 },   // optional
}

pub enum QueryMsg {
    Config {},
    PoolBalance {},
}
```

Core checks:

* `execute_contribute` rejects empty funds.  
* `execute_distribute` verifies `env.message.sender == env.contract.admin`.  
* Shares = `pool / N_beneficiaries`.

### Build & Optimise

```bash
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename $(pwd))_cache",target=/code/target \
  cosmwasm/workspace-optimizer:0.13.0
```

`artifacts/equalis_redistribute.wasm` generated.

---

<a name="deploying"></a>
## 5. Deploying the Contract

```bash
# 5.1 Store code
equalisd tx wasm store artifacts/equalis_redistribute.wasm \
  --from richman --chain-id equalis --gas auto --fees 10000ueqls -y
equalisd query wasm list-code             # note CODE_ID
# 5.2 Instantiate
CONTRACT_ADDR=$( \
 equalisd tx wasm instantiate <CODE_ID> \
 '{"beneficiaries":["$(equalisd keys show user1 -a)","$(equalisd keys show user2 -a)"],"threshold":"20000000000000"}' \
 --from richman \
 --admin $(equalisd keys show LakshmiAI -a) \
 --label "EqualisRedistribute" --chain-id equalis -y \
 | jq -r '.logs[0].events[-1].attributes[] | select(.key=="_contract_address").value' )
echo "Contract at $CONTRACT_ADDR"
```

---

<a name="ai"></a>
## 6. LakshmiVault AI Automation (Off‑chain)

Minimal Python sketch (`ai_agent.py`):

```python
from cosmpy.aerial.client import LedgerClient
from cosmpy.aerial.wallet import Wallet

CHAIN_RPC = "http://localhost:26657"
client = LedgerClient(chain_id="equalis", url=CHAIN_RPC)

ai = Wallet.from_mnemonic("...")           # LakshmiAI mnemonic
contract = "equalis1..."                   # CONTRACT_ADDR

# Trigger distribution once a year (simulated)
msg = {"Distribute": {}}
client.execute_contract(ai, contract, msg, gas_limit=300000)
print("Redistribution triggered.")
```

Run:

```bash
python ai_agent.py
```

---

<a name="zk"></a>
## 7. Simulating the ZK Revenue Proof

1. **richman** transfers the excess 5 000 000 EQLS:

```bash
equalisd tx bank send richman $CONTRACT_ADDR 5000000000000ueqls -y
```

2. **LakshmiAI** calls `Distribute` (script above).

=> Pool emptied, each beneficiary gets 2 500 500 EQLS.

No revenue amount ever stored on‑chain ⇒ confidentiality preserved.

---

<a name="tests"></a>
## 8. End‑to‑End CLI Tests

| Test | Command | Expected |
|------|---------|----------|
| Voluntary contribution | `equalisd tx wasm execute $CONTRACT_ADDR '{"Contribute":{}}' --amount 1000000000ueqls --from user1 -y` | Pool +1 000 EQLS |
| Unauthorized distribute | `equalisd tx wasm execute $CONTRACT_ADDR '{"Distribute":{}}' --from user1 -y` | **Error** "Unauthorized" |
| Admin distribute | `equalisd tx wasm execute $CONTRACT_ADDR '{"Distribute":{}}' --from LakshmiAI -y` | Funds split equally |
| Update threshold | `equalisd tx wasm execute $CONTRACT_ADDR '{"UpdateThreshold":{"new_threshold":"18000000000000"}}' --from LakshmiAI -y` | Config shows new threshold |

---

<a name="architecture"></a>
## 9. Architecture Recap

```
+-------------------------+
|  Cosmos SDK / Equalis   |
|  (CometBFT consensus)   |
+-----------+-------------+
            |
  CosmWasm module (wasmd)
            |
+-----------v-------------+
|  EqualisRedistribute    | <-- smart‑contract vault
+-----------+-------------+
            | exec / query
+-----------v-------------+
| LakshmiVault AI (off‑chain script) |
+-----------+-------------+
            |
  Users wallets (Keplr/CLI)
```

---

<a name="legal"></a>
## 10. Legal & Compliance Notes

* **Voluntary opt‑in** is mandatory – otherwise looks like private taxation.  
* Token $EQLS might fall under **MiCA** in EU ⇒ consult counsel.  
* Worldwide payouts require **KYC/AML** to avoid sanctions violations.  
* AI governance faces upcoming **EU AI Act** obligations (audit logs, accountability).  
* A DAO or non‑profit foundation should hold the admin keys & assume liability.

---

<a name="conclusion"></a>
## 11. Conclusion & Next Steps

The prototype proves that **automated, on‑chain redistribution above a hard income cap is technically feasible** using Cosmos SDK + CosmWasm.  
Future work:

1. Proper zero‑knowledge proof integration (Groth16 / BLS12‑381 once stable).  
2. Front‑end dashboard & mobile wallet UX.  
3. DAO governance layer and real AI decision engine.  
4. Regulatory alignment (opt‑in contracts, regional compliance).  

> **20 millions max. Above that? Share the surplus – instantly, transparently, consciously.**

---

© 2025 Equalis Lab – MIT License
