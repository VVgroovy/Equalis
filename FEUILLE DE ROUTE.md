# **Equalis 2.0 – PoS Blockchain scalable, confidentielle & 100 % EVM‑compatible**

*(Prototype open‑source – version 2025‑04‑21)*

> Redistribuer en temps réel tout revenu annuel > 20 M € grâce au jeton natif **$EQLS**.
>
> • Consensus : Proof‑of‑Stake CometBFT (≈ 2 s de finalité)  
> • Exécution : Ethermint (EVM) + CosmWasm + Secret‑Wasm  
> • Scalabilité : 10 000 TPS (blocs > 1 Mo & parallélisme Cosmos SDK)  
> • Confidentialité : contrats Secret‑Wasm (état chiffré)  
> • Fonction clé : contrat **`EqualisRedistribute`** – plafonne tout revenu à 20 M €/an et redistribue l’excédent à tous les adultes inscrits.  

---

## Table des matières
1. [Vision](#vision)
2. [Architecture](#architecture)
3. [Mise en route rapide](#mise-en-route-rapide)
4. [Modules cœur](#modules-cœur)
5. [Feuille de route](#feuille-de-route)
6. [Gouvernance & tokenomics](#gouvernance--tokenomics)
7. [Sécurité & conformité](#sécurité--conformité)
8. [Structure du dépôt](#structure-du-dépôt)
9. [Contribuer](#contribuer)
10. [Licence](#licence)

---

## Vision
Equalis vise à **partager la richesse** : tout revenu personnel annuel dépassant 20 M € est automatiquement redistribué en temps réel via la blockchain. Le système repose sur :
* **Incitations économiques** (staking / slashing) pour la sécurité.  
* **Preuves de revenu confidentielles** (Secret‑Wasm + placeholder ZK).  
* **Gouvernance déléguée** à l’IA auditable **LakshmiVault**.

---

## Architecture
```
┌───────────────────────────────────────────────────────────────┐
│ Front‑end React  •  wagmi (EVM)  •  CosmJS (Cosmos)          │
├───────────────────────────────────────────────────────────────┤
│ SDK TypeScript   •  GraphQL indexer (Hasura)                 │
├───────────────────────────────────────────────────────────────┤
│ Smart‑contracts Layer                                        │
│ ├─ CosmWasm public (EqualisRedistribute, CW20)               │
│ ├─ Secret‑Wasm private (IncomeProof, KYC attest)             │
│ └─ Solidity / Vyper (via Ethermint)                          │
├───────────────────────────────────────────────────────────────┤
│ Execution VMs: Ethermint │ CosmWasm │ Secret‑Wasm            │
├──────────────────┬───────────────────────────────────────────┤
│ PoS CometBFT     │ Data Availability (local blobs, 4844‑like)│
├──────────────────┴───────────────────────────────────────────┤
│ Inter‑Chain IBC  •  Bridges (Ethereum ↔ Equalis ↔ Secret)     │
└───────────────────────────────────────────────────────────────┘
```
### Points clés
| Couche | Choix | Raison |
|--------|-------|--------|
| **Consensus** | CometBFT PoS | Finalité 2 s, slashing natif |
| **EVM** | Ethermint | Compatibilité byte‑code complète |
| **Confidentialité** | Secret‑Wasm | État & messages chiffrés |
| **Redistribution** | CosmWasm public | Simplicité d’audit |
| **Interop** | IBC + pont Ethereum | Liquidité et adoption |

---

## Mise en route rapide
### Prérequis
* Go ≥ 1.22, Rust (stable) + target `wasm32-unknown-unknown`
* Docker, Ignite CLI `v0.30+`, Node 18+ (front‑end)

### Devnet 1 nœud
```bash
# 1. Cloner le dépôt
$ git clone https://github.com/equalis-chain/equalis.git && cd equalis

# 2. Lancer la chaîne locale
$ ignite chain serve        # build & start node + REST + gRPC

# 3. Démonstration redistrib.
$ ./scripts/demo.sh          # richman → 5 M EQLS → redistribution
```

### Interagir côté EVM
```bash
# Start JSON‑RPC (Ethermint)
$ evmosd start --json-rpc.api eth,txpool,personal,net,web3
# Ajouter au wallet Metamask :
  RPC URL  : http://localhost:8545  |  Chain ID : 777
```

---

## Modules cœur
| Domaine | Description | Fichiers |
|---------|-------------|----------|
| **EqualisRedistribute** | Contrat CosmWasm public qui reçoit les fonds > 20 M € et les redistribue proportionnellement. | `contracts/redistribute/` |
| **IncomeProof (Secret)** | Contrat Secret‑Wasm : l’utilisateur soumet une preuve chiffrée, validée off‑chain par l’IA. | `contracts/income_proof/` |
| **LakshmiVault AI** | Script Python (off‑chain) qui surveille la chaîne, valide les preuves et déclenche `Distribute`. | `ai/lakshmi_vault/` |
| **CW20 $EQLS** | Implémentation cw20‑base (optionnel si $EQLS natif). | `contracts/cw20_eqls/` |

---

## Feuille de route
| Phase | Période | Livrables |
|-------|---------|-----------|
| 0 – Spécification | S 1‑2 | RFC, cadrage légal MiCA |
| 1 – Bootstrap chaîne | S 3‑6 | Modules Ethermint & Secret‑Wasm intégrés |
| 2 – Contrats publics | S 7‑9 | `EqualisRedistribute`, tests multitest |
| 3 – Contrats privés | S 10‑13 | IncomeProof + API zk‑placeholder |
| 4 – Devnet multi‑VM | S 14‑15 | Bench ≥ 10 000 TPS, dashboards |
| 5 – Testnet public | S 16‑23 | Bug‑bounty, faucet, explorer |
| 6 – Mainnet Genesis | S 24‑27 | ≥ 64 validateurs, pont Ethereum actif |

---

## Gouvernance & tokenomics
* **Deux DAO** :
  * *Tech DAO* (validateurs + builders) – décide upgrades réseau.
  * *Ecosystem DAO* (détenteurs $EQLS) – gère trésor & grants.
* **Inflation 6 % → 2 %** décroissante, récompenses de staking.
* **Restaking** vers EigenLayer dès 2026 pour renforcer la sécurité inter‑chaînes.

---

## Sécurité & conformité
* Slashing : 100 % (double‑sign), 2 % (downtime > 8 h).  
* MEV : proposer‑builder separation (PBS) prévu Q4 2025.  
* **KYC / AML** via attestations DID + Secret‑contracts.  
* Conformité **MiCA** : enregistrement CASP + livre blanc public avant mainnet.  
* Audit code : Trail of Bits & Halborn (phases 4‑5).

---

## Structure du dépôt
```text
contracts/            # CosmWasm & Secret‑Wasm
  ├─ redistribute/    # EqualisRedistribute
  ├─ income_proof/    # ZK‑placeholder
  └─ cw20_eqls/       # CW20 optionnel
cmd/                  # Binaire de la chaîne (Go)
ai/                   # Scripts LakshmiVault AI
scripts/              # Helpers (demo, faucet, benchmarks)
frontend/             # dApp React (wagmi + CosmJS)
infra/                # Docker, Helm charts, Grafana dashboards
```

---

## Contribuer
Les contributions sont les bienvenues ! Merci de lire `CONTRIBUTING.md` et d’ouvrir une *issue* avant toute PR majeure.

---

## Licence
Code sous **Apache‑2.0**.  
© 2025 Equalis Foundation – *no financial advice, use at your own risk.*
