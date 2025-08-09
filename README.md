## Equalis — Protocole de redistribution avec plafond salarial (Cap & Redistribute)

Equalis est une crypto/infra conçue pour redistribuer automatiquement les dépassements de rémunération au-delà d’un plafond annuel (par défaut 20 000 000.00 unités du token de paie), vers des adultes éligibles qui en font la demande. Elle s’appuie sur:

- Contrats on-chain vérifiables (paie plafonnée, pool de redistribution, registre d’éligibilité)
- Gouvernance timelock + vote (ERC20Votes)
- Automatisation hebdomadaire (compatible Chainlink)
- Scalabilité massive via distributions par epochs (Merkle claims)
- Confidentialité: identités pseudonymes (hash), option ZK pour âge/unicité

### Points clés
- Plafond annuel par identité (`CompensationLimiter`), appliqué à la source côté paie (`RedistributivePayroll`).
- Dépassement redirigé vers `RedistributionPool`, redistribution égale en batches (hebdo par défaut).
- Registre `EligibilityRegistry`: atteste l’éligibilité (adultes opt-in) sans PII on-chain; hook vérificateur ZK optionnel.
- Gouvernance: `GovernanceToken (EQT)` + `EqualisGovernor` + `TimelockSetup`.
- Scalabilité: `MerkleEpochDistributor` pour des millions de bénéficiaires.

### Aperçu rapide du code (extraits)

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

Pour les détails, voir `contracts/` et `docs/`.

### Installation

```bash
pnpm install || npm install
npx hardhat compile
```

### Configuration (.env)
Copiez `.env.example` en `.env` et remplissez:

```
PAYMENT_TOKEN_ADDRESS= # Adresse stablecoin (ex. USDC)
PAYMENT_TOKEN_DECIMALS=6
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
RPC_URL=http://127.0.0.1:8545
```

### Déploiement local

```bash
npx hardhat node &
npx hardhat run scripts/deploy.ts --network localhost
```

Par défaut, un `MockStablecoin` est déployé localement et le plafond annuel est aligné sur les `PAYMENT_TOKEN_DECIMALS` (20 000 000.00).

### Déploiement sur un réseau (ex. Sepolia)

```bash
export PAYMENT_TOKEN_ADDRESS=0x...   # stablecoin réel
export PAYMENT_TOKEN_DECIMALS=6
npx hardhat run scripts/deploy.ts --network sepolia
```

### Attestation & employeurs (scripts)

```bash
export REGISTRY=0x...
export PAYROLL=0x...
export EMPLOYER=0xEmployeur
export SUBJECT=0xEmploye
npx hardhat run scripts/admin.ts --network sepolia
```

### Automatisation hebdo (Chainlink)
- Déployez `AutomationDistributor` et pointez un Upkeep sur `performUpkeep(bytes)`.
- Paramètres: `batchSize` (nb max de bénéficiaires par appel), `minInterval` (ex. 7j).

### Distribution à grande échelle (Merkle epochs)
1. Off-chain: calculez allocations + racine Merkle.
2. On-chain: alimentez le contrat puis `setEpochRoot(epochId, root, totalAllocated)`.
3. Les bénéficiaires réclament via `claim(index, account, amount, proof)`.

### Gouvernance
1. Déployer `GovernanceToken`, `TimelockSetup`, `EqualisGovernor`.
2. Transférer les rôles admin des contrats (registry/limiter/pool/payroll) au timelock.
3. Paramétrer cadence/fees/attesteurs via propositions avec timelock.

### Politique de frais (optionnelle ≤ 5%)
- Si activée, la ponction ne s’applique que sur le dépassement redistribué (jamais les salaires), avec plafond dur et trajectoire dégressive décidés par gouvernance.

### IA “Lakshmi” (copilote)
- Surveille on/off-chain, produit rapports d’équité, détecte anomalies/Sybil, propose des changements de paramètres (validation par vote, jamais de contrôle direct des fonds).
Voir `docs/ARCHITECTURE.md` et `docs/COMPLIANCE_PRIVACY.md`.

### Références
- `docs/ARCHITECTURE.md`: architecture détaillée
- `docs/TOKENOMICS.md`: principes économiques
- `docs/COMPLIANCE_PRIVACY.md`: conformité et privacy

### Licence
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
