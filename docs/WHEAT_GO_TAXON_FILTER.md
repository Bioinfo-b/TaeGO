# Wheat GO Taxon-Constraint Filtering

## Purpose

The `taego wheat` workflow performs GO enrichment in wheat gene space. The
workflow removes only gene-GO relationships that are explicitly incompatible
with wheat according to the official Gene Ontology taxon-constraint resource.

The filter was introduced because a small number of projected or propagated
annotations could carry GO terms whose official taxon constraints are
restricted to animal lineages, even though the analysis target is
*Triticum aestivum*.

## Official source

The frozen compatibility resource is:

~~~~text
wheat_go_taxon_compatibility_2024-09-08.tsv
~~~~

The filtering table distributed with TaeGO is:

~~~~text
wheat_animal_exclusive_go_2024-09-08.tsv
~~~~

The target taxon is wheat:

~~~~text
NCBITaxon:4565
~~~~

The resource snapshot date is:

~~~~text
2024-09-08
~~~~

## Selection rule

A GO term is included in the wheat animal-exclusive table only when all of
the following conditions hold:

1. The official status is `BLOCK_IN_TAXON`.
2. The constraint contains a positive `RO:0002162` (`in_taxon`) relation.
3. The constrained taxon belongs to the NCBI animal lineage, including
   Metazoa descendants.

The frozen table records the source status, constraint details, taxon name,
target taxon, and the filter rule for auditability.

## What is removed

Only gene-GO pairs whose GO term occurs in the frozen animal-exclusive table
are removed from the `taego wheat` annotation universe.

The filter does not remove an entire gene. A gene remains eligible through all
of its other valid GO annotations.

The filter does not remove:

- plant-compatible GO terms;
- broadly conserved GO terms;
- GO terms with no animal-specific blocking constraint;
- terms with `ALLOW`, `ALLOW_NO_CONSTRAINT`, or `NO_STATUS` status;
- valid annotations from any of the six wheat annotation sources.

No keyword-based filtering is used.

## Audit outputs

For every wheat run, TaeGO writes:

~~~~text
<prefix>_animal_filter_summary.tsv
<prefix>_animal_blocked_pairs.tsv
~~~~

The summary records the number of removed pairs, affected genes, removed GO
terms, retained pairs, and the frozen filtering resource.

The blocked-pairs table records the exact gene-GO relationships removed by the
filter. It is an audit table and is not a final enrichment result.

## Regression validation

The regression set contains 5,722 wheat IDs that previously exposed
animal-specific GO terms.

The validated 2.0.0 run produced:

~~~~text
foreground IDs:       5,722
mapped IDs:            2,024
unmapped IDs:          3,698
animal GO in all.csv:  0
animal GO in sig.csv:  0
~~~~

The regression therefore confirms that animal-exclusive GO terms are absent
from the final wheat enrichment tables while valid remaining annotations are
retained.

## Scope boundary

This filter applies to:

~~~~text
taego wheat
~~~~

It does not alter the human/mouse conserved-function workflow:

~~~~text
taego wheat-mammal
~~~~

The mammalian workflow continues to use its independent direct-OMA mapping,
route provenance, human/mouse analysis modes, and wheat-space enrichment.
