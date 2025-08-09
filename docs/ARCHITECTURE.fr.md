### Equalis: Architecture de redistribution

Objectifs:
- Cap salarial appliqué à la source via la paie
- Redistribution équitable de l’excédent aux adultes éligibles
- Respect privacy: identités pseudonymes (hash), ZK optionnel
- Gouvernance timelock + votes
- Scalabilité (Merkle epochs)

Composants on-chain:
- `EligibilityRegistry`: lie `address -> identityId` (hash de VC), gère l’éligibilité, attesteurs autorisés, option `verifier` ZK.
- `CompensationLimiter`: plafond annuel par identité (consommation + suivi de période).
- `RedistributivePayroll`: paie plafonnée; verse l’autorisé à l’employé et redirige l’excédent au `RedistributionPool`.
- `RedistributionPool`: détient les excédents et redistribue en batchs (hebdo par défaut), pagination anti-OOG.
- `GovernanceToken (EQT)`: token de vote (ERC20Votes).
- `EqualisGovernor` + `TimelockSetup`: gouvernance timelockée.
- `AutomationDistributor`: adaptateur Chainlink Automation (déclenche `distribute`).
- `MerkleEpochDistributor`: distribution par epochs, claims avec preuves Merkle.

Services off-chain:
- Attestation VC (âge/unicité) → enregistrement pseudonyme on-chain.
- Paymaster/AA (gasless), oracles/ERP paie.
- Détection Sybil/risques (Lakshmi).

Choix & évolutions:
- Stablecoin recommandé pour la paie.
- Passage progressif du push vers Merkle claims pour l’échelle 10M+.
- Ajout ZK (preuves d’âge/unicité) et cap multi‑employeurs (roadmap).


