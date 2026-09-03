# Wheat–mammal mapping schema

This page documents the mapping fields used by the `wheat-mammal` workflow.
For installation and command examples, see [../INSTALL.md](../INSTALL.md) and
[USAGE.md](USAGE.md).

## Why TaeGO 1.1.0 separates routes

TaeGO 1.0.0 pooled evidence from four routes into one final relation record:

- direct OMA wheat↔human/mouse;
- wheat→rice (GeneTribe) → mammal (OMA);
- wheat→maize (GeneTribe) → mammal (OMA);
- wheat→Arabidopsis (GeneTribe) → mammal (OMA).

The old aggregation ranked relation types across routes. Consequently a relay
`1:1` could overwrite a direct wheat–mammal `m:n` relation. The previous rank map
also omitted the OMA `m:1` category, leaving some genuine direct relations as
`?`. TaeGO 1.1.0 corrects representation without discarding the historical
files or changing the underlying final pair set.

## Corrected route-separated schema

The rebuilt tables contain:

```text
wheat_v21
target_omaid
target_ensembl_gene
target_uniprot
direct_present
direct_rel_type
rice_support
rice_rel_type
maize_support
maize_rel_type
arabidopsis_support
arabidopsis_rel_type
relay_support_n
evidence_routes
```

A relation type from one route is never ranked against or substituted for a
relation type from another route.

`target_omaid` and `target_uniprot` are retained as provenance. The Ensembl gene
ID is the mammalian gene-level bridge used to retrieve the animal GO annotation.
The final enrichment statistical unit remains the **wheat gene**, because GO is
projected back onto `wheat_v21` before enrichment.

## Real rebuild audit

The full rebuild preserved the exact pair counts while separating route
provenance:

```text
human: 63,641 total pairs; 44,818 direct; 18,823 relay-only
mouse: 99,639 total pairs; 72,765 direct; 26,874 relay-only
```

The OMA target→Ensembl gene bridge was one-to-one for all target OMA IDs used:

```text
human: 4,408 OMA targets -> 4,408 Ensembl genes
mouse: 4,664 OMA targets -> 4,664 Ensembl genes
```

No OMA target mapped to multiple Ensembl genes in this rebuild.

## Scientific use in Part B

Primary animal-derived wheat GO projection uses only rows with
`direct_present = TRUE`. OMA defines 1:1, 1:n, m:1 and m:n as pairwise orthology
cardinalities, so all direct OMA relation types are retained. Rice/maize/
Arabidopsis routes remain supporting provenance and relay-only endpoints are not
promoted to direct orthology.

The projection then joins the mammalian Ensembl gene to experimentally
supported GO annotations and assigns those GO terms to the corresponding wheat
gene. Enrichment is performed on the resulting wheat gene→GO table.

## Historical preservation

The original 1.0.0 mapping inputs and analysis remain available for historical
reproduction.

## References

- Altenhoff AM et al. 2024. OMA orthology in 2024. *Nucleic Acids Research*
  52:D513–D521. DOI: 10.1093/nar/gkad1020.
- Altenhoff AM et al. 2015. The OMA orthology database in 2015: function
  predictions, better plant support, synteny view and other improvements.
  *Nucleic Acids Research* 43:D240–D249. DOI: 10.1093/nar/gku1158.
- Gene Ontology / GOA Curators. GO_REF:0000107. Automatic transfer of
  experimentally verified manual GO annotation data to orthologs using Ensembl
  Compara. https://geneontology.org/GO_REF/0000107
