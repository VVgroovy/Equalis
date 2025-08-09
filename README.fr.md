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
- `docs/ARCHITECTURE.md` et `docs/ARCHITECTURE.fr.md`
- `docs/TOKENOMICS.md` et `docs/TOKENOMICS.fr.md`
- `docs/COMPLIANCE_PRIVACY.md` et `docs/COMPLIANCE_PRIVACY.fr.md`
- `docs/ROADMAP.md` et `docs/ROADMAP.fr.md`

### Licence
MIT


