### Lakshmi — IA copilote d’équité et de gouvernance

Objectifs:
- Surveiller on-chain/off-chain, détecter anomalies/Sybil
- Mesurer l’équité (Gini/Theil) et proposer des corrections
- Simuler paramètres (cadence, batchSize, fees ≤ 5%) avant proposition gouvernée
- Aider à la conformité sans PII, avec preuves ZK quand disponibles

Pipeline minimal:
- Ingestion: The Graph/Subsquid + événements off-chain (attestation/paie)
- Stockage: Parquet/S3 + bus d’événements
- Modèles: GNN (Sybil), métriques d’équité, prévision de coûts gaz/liquidité
- Output: Rapports hebdo + propositions Governor (via timelock), jamais de contrôle direct de fonds

Garde-fous:
- Lecture seule, clés isolées, audit complet
- Explicabilité (features importances/SHAP)
- Gouvernance > IA: timelock + veto communautaire


