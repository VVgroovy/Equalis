### Tokenomics et design économique

- Moyen de paie: stablecoin (valeur stable). Les contrats sont agnostiques.
- Flux d’excédent: tout au-dessus du cap → `RedistributionPool`.
- Éligibilité: adultes opt-in via VC; on-chain pseudonyme.
- Cadence: hebdomadaire par défaut, gouvernable.
- Gouvernance (EQT): ERC20Votes; finance R&D, paymaster, bounties.
- Incitations: employeurs (ESG), attesteurs (bounties + staking), bénéficiaires (gasless).

Risques & mitigations:
- Sybil: multi‑attesteurs, réputation, ZK.
- Incitations perverses: redistribution égalitaire par epoch; pondération “besoin” optionnelle via proofs off-chain.
- Chocs de marché: réserve/treasury de lissage, cadence ajustable par gouvernance.

Frais (optionnels ≤ 5% sur l’excédent, jamais sur salaires): dégressifs et timelockés.


