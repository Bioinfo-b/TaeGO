# Changelog

## 1.1.0

### Scientific changes

- Canonical analysis commands are `wheat` and `wheat-mammal`; mammalian target
  selection is explicit through `-t human|mouse|both`.
- Clarified Part A as **TGT-calibrated Single Sample statistics plus an
  independently expanded six-source wheat annotation**, not exact historical
  TGT annotation reproduction and not TGT ortholog-mode replication.
- Preserved Part A settings: hypergeometric ORA, separate BP/MF/CC BH,
  minGSSize 5, maxGSSize 1200 and FDR 0.05.
- Human/mouse GO knowledge is projected through direct OMA orthology onto wheat
  genes, followed by wheat-space GO enrichment.
- Rebuilt human/mouse mapping tables with route-specific OMA relation types,
  fixing cross-route `rel_type` overwriting and the historical missing `m:1`
  rank category while retaining all original mapping/provenance information.
- Human and mouse remain independent analyses; they are not merged before GO
  testing.
- Primary 1.1.0 animal projection uses IDA/IEP/IGI/IMP/IPI source annotations
  and excludes GO:0005515, using GO_REF:0000107 as evidence-filter precedent.
  TaeGO uses OMA rather than Ensembl Compara and does not claim to reproduce the
  Compara-specific 40% identity rule.
- `allEvidence` remains as an independent reference/sensitivity output.
- Plant relay routes remain provenance/triangulation support and do not create
  direct wheat–mammal orthology.

### CLI and auditability

- Added canonical `-i/--input`.
- Standardized mammalian projection on `wheat-mammal -t human|mouse|both`.
- Added input trimming, duplicate removal, explicit unmapped-gene reports,
  projected foreground gene→GO provenance and mapping-audit outputs.
- Normal completion with no enrichment writes header-only result tables.

### Integrity and packaging

- `taego validate` verifies the SHA256 manifest and data schemas.
- `doctor` checks all required runtime components including GenomeInfoDbData;
  `info` reports validated-reference versus actual versions.
- Release and installer bundles use checksum verification.
- Frozen `environment.yml` and Bioconductor annotation-data recovery guidance
  are included.

### GO taxon compatibility QC

- Added formal GO taxon-constraint QC before Part B wheat-space ORA.
- Pinned the final compatibility contract to GO release `2024-09-08` for
  *Triticum aestivum* (`NCBITaxon:4565`).
- Added the frozen runtime payload `data/wheat_go_taxon_compatibility_2024-09-08.tsv`
  (SHA256 `61cdf7c9ec918e8c35f32315a6863454f4f61d8d4384aefecc572c7710adf95e`).
- Excluded formal `BLOCK_IN_TAXON` and `BLOCK_NEVER_IN_TAXON` projected
  wheat-GO pairs while retaining `ALLOW` and `ALLOW_NO_CONSTRAINT`.
- Preserved the raw orthology-derived projection separately for provenance
  and added deterministic taxon-filter audit output.
- Taxon compatibility is determined from the frozen formal GO taxon-constraint
  resource rather than an ad-hoc biological blacklist.
- No sequence identity, coverage, orthology-consensus, ORA threshold, or
  BP/MF/CC multiple-testing rule was changed by this correction.

## 1.0.0 — historical baseline

First packaged TaeGO release. The system installation and original CLI/runtime
validation remain a frozen historical baseline and are not modified by 1.1.0.
