# TaeGO 1.1.0 Methods and Evidence Contract

This document distinguishes **published/officially supported methods** from
**TGT-calibrated project settings** and from **engineering-only behavior**.
Scientific thresholds are not introduced without a cited basis.

## 1. Module A — TGT-calibrated wheat GO enrichment

### 1.1 Scope

The benchmarked TGT workflow was **Single Sample GO Enrichment** on
*Triticum aestivum* rather than the optional TGT `Use orthologs` mode. TGT's
web interface exposes ortholog use as optional. TaeGO therefore describes its
wheat module as **TGT-calibrated**, not as an exact reproduction of the TGT
ortholog-mode workflow or of TGT's unavailable historical annotation snapshot.

TGT/GeneTribe reference:

- Chen Y, Song W, Xie X, et al. 2020. *A Collinearity-Incorporating Homology
  Inference Strategy for Connecting Emerging Assemblies in the Triticeae Tribe
  as a Pilot Practice in the Plant Pangenomic Era.* Molecular Plant
  13:1694–1708. DOI: **10.1016/j.molp.2020.09.019**.
- TGT GOEnrichment web interface: https://wheat.cau.edu.cn/TGT/m28/?navbar=GOEnrichment
- GeneTribe file-format documentation:
  https://chenym1.github.io/genetribe/tutorial/fileformats.html

GeneTribe documents `.one2one` as **RBH + SBH**; TaeGO therefore calls these
`1-to-its-best` homolog relationships rather than strict phylogenetic
`ortholog_one2one` assignments.

### 1.2 Six-source wheat annotation

TaeGO's production wheat annotation is an independent expanded resource:

| Source | Role |
|---|---|
| IWGSC RefSeq v2.1 functional annotation | direct wheat annotation |
| InterProScan 5.76-107.0 | domain/function-derived GO |
| eggNOG-mapper 2.1.13 / eggNOG 5.0.2 | orthology/function-derived GO |
| Rice IRGSP-1.0 GO | GeneTribe `1-to-its-best` homolog transfer |
| Maize B73 RefGen v4 GO | GeneTribe `1-to-its-best` homolog transfer |
| Arabidopsis TAIR10 GO | GeneTribe `1-to-its-best` homolog transfer |

Cross-plant functional annotation transfer has a wheat-specific precedent:

- Tulpan D, Leger S, Tchagang A, Pan Y. 2015. *Enrichment of Triticum aestivum
  gene annotations using ortholog cliques and gene ontologies in other
  plants.* BMC Genomics 16:299. DOI: **10.1186/s12864-015-1496-2**.

The six annotation sources are unioned at the gene–GO level before a single
enrichment analysis. This is an annotation expansion, not three separate
species enrichments followed by significance-result merging.

### 1.3 GO ancestor propagation

The union is expanded from each positive GO annotation to its parent terms
using GO.db (`GOBPANCESTOR`, `GOMFANCESTOR`, `GOCCANCESTOR`). This follows the
GO transitivity/true-path semantics: positive annotations propagate upward to
parent terms through applicable transitive relations.

Official reference: Gene Ontology, “Introduction to GO annotations”:
https://geneontology.org/docs/go-annotations/

### 1.4 Statistical settings and evidence class

| Setting | TaeGO 1.1.0 | Evidence/basis |
|---|---:|---|
| Test | hypergeometric ORA | clusterProfiler enrichment framework; Yu et al. 2012 |
| GO aspects | BP/MF/CC separately | historical TGT Single Sample calibration |
| Multiple testing | BH separately within each aspect | historical TGT export/calibration + BH method |
| min gene-set size | 5 | TGT-calibrated interface/export setting |
| max gene-set size | 1200 | TGT-calibrated interface/export setting |
| significance | adjusted P < 0.05 | TGT-calibrated output convention |
| default background | all genes represented in TaeGO wheat annotation | clusterProfiler `universe` semantics; use custom study universe when available |

The calibration procedure recomputed TGT term P-values from foreground/background
ratios with `phyper()` and obtained zero numerical discrepancy for the 21-term
benchmark. This validates the **statistical calculation**, not identity of the
expanded TaeGO annotation resource with TGT's historical annotation.

General statistical references:

- Yu G, Wang L-G, Han Y, He Q-Y. 2012. *clusterProfiler: an R Package for
  Comparing Biological Themes Among Gene Clusters.* OMICS 16:284–287.
  DOI: **10.1089/omi.2011.0118**.
- Benjamini Y, Hochberg Y. 1995. *Controlling the False Discovery Rate: A
  Practical and Powerful Approach to Multiple Testing.* JRSS B 57:289–300.
  DOI: **10.1111/j.2517-6161.1995.tb02031.x**.
- clusterProfiler manual documents `universe`, `minGSSize`, `maxGSSize` and
  `pAdjustMethod`: https://bioconductor.org/packages/clusterProfiler/

For an experiment with a known assayed/tested gene universe, that custom
background should be supplied rather than substituting an unrelated whole
organism universe. Background choice materially affects ORA.

## 2. Module B — animal-derived conserved-function projection to wheat

### 2.1 Scientific question

Part B retains the original TaeGO design: use the deeper experimentally studied
functional knowledge in human or mouse to annotate orthologous wheat genes, then
perform enrichment in **wheat gene space**. The final statistical entities are
therefore wheat IWGSC RefSeq v2.1 gene IDs rather than mammalian genes.

This is a function-transfer/annotation-projection problem, not a target-species
functional-analysis problem. Orthology-based functional transfer is a long-
standing use of comparative genomics. OMA explicitly describes transfer of GO
function from well-studied organisms to less-studied genomes and has integrated
orthology-based GO prediction:

- Altenhoff AM, Škunca N, Glover N, et al. 2015. *The OMA orthology database in
  2015: function predictions, better plant support, synteny view and other
  improvements.* Nucleic Acids Research 43:D240–D249.
  DOI: **10.1093/nar/gku1158**.
- Altenhoff AM, Vesztrocy AW, Bernard C, et al. 2024. *OMA orthology in 2024.*
  Nucleic Acids Research 52:D513–D521. DOI: **10.1093/nar/gkad1020**.

### 2.2 Primary animal–wheat relationship: direct OMA pairwise orthology

TaeGO uses direct OMA wheat↔human and wheat↔mouse pairwise orthology. OMA
distinguishes 1:1, 1:n, m:1 and m:n pairwise orthology; lineage-specific
duplication can therefore create genuine co-orthology. TaeGO retains all direct
OMA relation types and records the relation cardinality rather than imposing an
unreferenced identity, coverage or `consensus_n` cutoff.

Supporting routes through rice, maize and Arabidopsis are stored separately:

```text
wheat -> rice        -> mammal
wheat -> maize       -> mammal
wheat -> Arabidopsis -> mammal
```

The relay routes are provenance/triangulation support only. They cannot create
or upgrade direct wheat–mammal orthology, because pairwise orthology is not
generally transitive in the presence of duplication.

The previous builder pooled route-specific relation types. Analysis of the rebuilt data
demonstrated that this could change the recorded direct
`rel_type`; TaeGO 1.1.0 therefore stores `direct_rel_type`, `rice_rel_type`,
`maize_rel_type` and `arabidopsis_rel_type` independently. The rebuild also
fixed the previous omission of `m:1` from the rank table. Pair sets
remain unchanged; only route provenance/cardinality representation is corrected.

### 2.3 Mammalian identifier bridge

OMA target identifiers are retained for provenance. OMA→Ensembl cross-references
are used to obtain gene-level human/mouse Ensembl IDs; stable-ID version suffixes
(e.g. `.6`) are removed while preserving the stable gene identifier. UniProt
cross-references are retained but are not counted as separate genes.

The real TaeGO 1.1.0 rebuild audit found:

- human: 4,408 OMA targets → 4,408 unique Ensembl genes, no one-to-many gene
  xrefs;
- mouse: 4,664 OMA targets → 4,664 unique Ensembl genes, no one-to-many gene
  xrefs.

Thus the bridge changes identifier representation without deleting wheat–mammal
relationship edges.

### 2.4 GO source annotations and projection evidence

Human and mouse annotations come from the frozen Bioconductor OrgDb resources
`org.Hs.eg.db 3.20.0` and `org.Mm.eg.db 3.20.0`, using `GOALL` so ancestor
annotations are represented consistently with the project’s propagated-GO
framework.

The publication-primary `experimental` projection uses the following evidence
codes:

```text
IDA, IEP, IGI, IMP, IPI
```

and excludes `GO:0005515` (`protein binding`). This evidence subset mirrors the
experimentally supported source annotations specified by Gene Ontology
**GO_REF:0000107**, an official orthology-projection method. GO_REF:0000107 also
uses Ensembl Compara orthology and a 40% peptide-identity requirement. TaeGO does
**not** import that Compara-specific identity threshold and does not claim to
reproduce GO_REF:0000107; TaeGO uses OMA pairwise orthology. The GO reference is
used specifically as precedent for source-annotation evidence restriction.

Reference: Gene Ontology Consortium / GOA Curators, GO_REF:0000107,
*Automatic transfer of experimentally verified manual GO annotation data to
orthologs using Ensembl Compara*.
https://geneontology.org/GO_REF/0000107

A separate `allEvidence` analysis retains all GOALL evidence present in the
OrgDb and is reported as a reference/sensitivity view.

### 2.5 Construction of the animal-derived wheat gene→GO table

For each species and evidence view:

1. retain route-table rows with `direct_present = TRUE`;
2. join the mammalian Ensembl gene to the species-specific OrgDb GO annotation;
3. transfer each retained GO term to the corresponding wheat gene;
4. collapse duplicate wheat–GO pairs;
5. retain full mammalian-ID, OMA relation-type and relay-support provenance in
   audit output.

The resulting enrichment table has the same statistical form as Part A:

```text
wheat_gene    GO_ID
```

Thus human/mouse knowledge is used to enrich wheat annotation depth without
changing the user's gene namespace or the statistical unit of the final GO test.

### 2.6 Wheat-space enrichment parameters

Because the projected annotation has been converted back to wheat gene space,
TaeGO applies the validated TGT-calibrated wheat ORA framework used by Part A:

| Parameter | Value | Basis |
|---|---:|---|
| test | hypergeometric ORA | TGT-calibrated / clusterProfiler `enricher()` |
| correction | Benjamini-Hochberg | TGT-calibrated, BP/MF/CC independently |
| minGSSize | 5 | TGT wheat Single Sample interface/calibration |
| maxGSSize | 1200 | TGT wheat Single Sample interface/calibration |
| significance | FDR < 0.05 | TGT default / project lock |

The default background is all wheat genes with at least one projected GO term
for the selected mammalian species and evidence view. If the source experiment
has a defined assayed/tested universe, `-b/--background` should be supplied;
TaeGO intersects it with the projected-annotation universe.

Human and mouse are never merged before hypothesis testing. The public Part B
interface is `taego wheat-mammal -t human|mouse|both`; `both` runs the two
species-specific analyses independently and reports both result sets.

### 2.7 Interpretation boundary

Projected GO terms reflect functional knowledge learned in the animal ortholog.
They should be interpreted as evidence for conserved molecular/cellular
machinery, not as literal proof of mammal-specific physiology in wheat. GO taxon
constraints are a formal mechanism for preventing inappropriate annotation
(Gene Ontology Consortium; Deegan, Dimmer & Mungall 2010). TaeGO 1.1.0 uses
formal, version-pinned GO taxon constraints rather than a custom
taxon-constraint blacklist.


## 3. Parameters that TaeGO intentionally does not invent

TaeGO 1.1.0 does **not** introduce:

- sequence identity or coverage cutoffs to manufacture “high-confidence” OMA
  orthology;
- a requirement for `consensus_n >= N` as a biological acceptance threshold;
- a relay count threshold that upgrades relay-only evidence to direct orthology;
- an animal-specific gene-set-size threshold unrelated to the validated wheat-space ORA;
- arbitrary taxon-specific GO deletions in only one evidence mode.

Such thresholds require a separate documented method/benchmark before they can
become scientific filters.

## 4. Software/runtime reference

The validated-reference runtime is frozen in `environment.yml` and
`manifest/runtime_versions.tsv`. `taego info` reports actual versus reference
versions; `doctor` tests package availability; `validate` verifies release
checksums and data schemas.

## 5. Claims that are supported and claims that are not

Supported:

- TaeGO `wheat` has broader wheat annotation coverage than the historical TGT
  benchmark used in this project.
- TaeGO combines six traceable annotation sources before one enrichment test.
- TaeGO `wheat-mammal -t human|mouse|both` uses direct OMA relationships to project animal GO annotations back to wheat before wheat-space ORA.

Not established solely by the current release:

- that the expanded annotation is biologically more accurate than TGT;
- that every relay-only endpoint is a direct wheat–mammal ortholog;
- that mammal-specific GO labels literally describe wheat physiology;
- that TaeGO is an exact reconstruction of TGT's historical annotation data.

## Final TaeGO 1.1.0 GO taxon-constraint quality control

TaeGO does not apply an ad-hoc biological blacklist when using formal,
version-matched GO taxon-constraint resources. Taxon compatibility is determined
from formal GO constraints rather than keyword-based or manually curated
GO-term exclusion rules.

In the final TaeGO 1.1.0 Part B workflow, animal-derived GO annotations are
first projected to wheat genes through direct OMA pairwise orthology. Before
wheat-space over-representation analysis, the resulting projected GO
annotations are subjected to formal Gene Ontology taxon-constraint quality
control.

The target is *Triticum aestivum* (`NCBITaxon:4565`) and the compatibility
contract is pinned to GO release `2024-09-08`. The final runtime bundles:

`data/wheat_go_taxon_compatibility_2024-09-08.tsv`

with SHA256:

`61cdf7c9ec918e8c35f32315a6863454f4f61d8d4384aefecc572c7710adf95e`

The frozen compatibility derivation is provenance-linked to:

- GO computed taxon constraints:
  `9b1ee1894fb6abc1e784326ea7c6dece211263b7173e31d0544d78d15c935856`
- GO taxon groupings:
  `648cb63eccfb0ffc89073f0c5659adbba1640f37cc39ea9a6255a36e5be4611f`
- NCBI taxonomy information used for the wheat lineage:
  `e22f0f7b21aabcf71f5967848115eb18be1d8c0dce21de45cb2ef2d43d031571`

Formal `in_taxon`/`only_in_taxon` and `never_in_taxon` constraints are used
to determine wheat compatibility. `BLOCK_IN_TAXON` and
`BLOCK_NEVER_IN_TAXON` wheat-GO pairs are excluded from the statistical
annotation universe. `ALLOW` and `ALLOW_NO_CONSTRAINT` pairs are retained.
GO identifiers absent from the frozen compatibility resource, or unsupported
status values, fail closed.

The raw direct-orthology-derived projection is retained separately for
provenance and is not destroyed by filtering. For each species/evidence mode,
TaeGO records the raw foreground projection, the filtered statistical
projection, and the taxon-filter audit before performing wheat-space ORA.

This implementation follows the formal GO taxon-constraint framework of
Deegan JI, Dimmer EC, and Mungall CJ (2010), *BMC Bioinformatics* 11:530,
DOI `10.1186/1471-2105-11-530`, PMID `20973947`.

The taxon-QC step does not introduce an OMA sequence-identity threshold,
coverage threshold, consensus-vote threshold, or any manually constructed
biological blacklist. The existing TGT-calibrated wheat-space ORA parameters
and the separate BP/MF/CC Benjamini-Hochberg correction remain unchanged.

