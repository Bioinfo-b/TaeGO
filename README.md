# TaeGO

**TaeGO — Triticum aestivum Gene Ontology toolkit**

Version **1.1.0**

TaeGO is a command-line toolkit for functional analysis of *Triticum aestivum*
(IWGSC RefSeq v2.1) gene sets. TaeGO 1.1.0 exposes two public analysis commands,
both accepting **wheat gene IDs** as input:

1. **`wheat`** — TGT-calibrated wheat GO over-representation analysis using the
   six-source wheat GO annotation resource.
2. **`wheat-mammal`** — project experimentally supported human and/or mouse GO
   knowledge to direct OMA orthologous wheat genes, then perform GO enrichment
   in wheat gene space. Select the source species with `-t human`, `-t mouse`,
   or `-t both`.

Human and mouse remain independent analyses even when `-t both` is used; TaeGO
does not merge their GO hypothesis spaces before testing. TaeGO does **not**
claim to support arbitrary plant or animal inputs.

## Download

The latest TaeGO release is available from GitHub Releases:

https://github.com/Bioinfo-b/TaeGO/releases

Current release:

- TaeGO v1.1.0
- Platform: Linux x86_64
- Installer:
  `TaeGO-1.1.0-Linux-x86_64.sh`

SHA256 verification is provided with the release assets.

## Installation requirements

TaeGO is distributed in two forms:

1. **Standalone release installer (recommended for end users)**
   - Installs the TaeGO application, scripts and reference resources.
   - Requires a prepared micromamba/conda environment containing the validated R/Bioconductor runtime.

2. **Source repository installation**
   - Intended for developers and users who want to inspect or modify the workflow.
   - Requires a micromamba-managed environment.

### System requirements

TaeGO is validated on Linux x86_64 systems.

Required for source installation:

- Bash shell
- micromamba
- Internet access during environment setup
- Sufficient disk space for R/Bioconductor packages and reference resources

Example environment setup:

```bash
micromamba create -n taego -f environment.yml
micromamba activate taego
```

The standalone release package installs TaeGO into an existing validated runtime environment and does not replace the runtime setup step.

## Quick start

Wheat GO enrichment:

```bash
taego wheat -i genes.txt -o result
```

Animal-derived conserved-function projection to wheat:

```bash
taego wheat-mammal -i genes.txt -o result -t human
taego wheat-mammal -i genes.txt -o result -t mouse
taego wheat-mammal -i genes.txt -o result -t both
```

With a custom wheat analysis universe:

```bash
taego wheat -i genes.txt -o result -b background.txt
taego wheat-mammal -i genes.txt -o result -b background.txt -t human
taego wheat-mammal -i genes.txt -o result -b background.txt -t mouse
taego wheat-mammal -i genes.txt -o result -b background.txt -t both
```

`-i/--input` is the canonical input interface. Positional foreground input is
accepted for compatibility within the two public commands, but new scripts
should use `-i`.

## `wheat`: TGT-calibrated statistics with an expanded wheat annotation

The historical calibration used TGT **Single Sample GO Enrichment** for wheat,
with the optional `Use orthologs` mode not enabled. TaeGO therefore does not
claim that this module reproduces TGT's optional ortholog-mode analysis.

The statistical framework was reconstructed/calibrated against TGT exports:

- hypergeometric over-representation analysis;
- BP, MF and CC tested separately;
- Benjamini-Hochberg correction within each GO aspect;
- gene-set size 5–1200;
- FDR < 0.05 for the significant-result file.

The annotation is intentionally **not** an exact copy of TGT's unavailable
historical annotation snapshot. TaeGO uses a modern six-source wheat annotation:

1. IWGSC RefSeq v2.1 official functional annotation;
2. InterProScan;
3. eggNOG-mapper;
4. rice GO transferred through GeneTribe `1-to-its-best` homologs;
5. maize GO transferred through GeneTribe `1-to-its-best` homologs;
6. Arabidopsis GO transferred through GeneTribe `1-to-its-best` homologs.

The union is expanded to GO ancestors. The production table contains 90,339
annotated wheat genes. Broader coverage is not claimed to mean higher biological
accuracy without an independent benchmark.

GeneTribe's `.one2one` table is `RBH + SBH` and is therefore described as
`1-to-its-best` homolog mapping rather than strict phylogeny-derived
`ortholog_one2one` assignment.

## `wheat-mammal`: animal knowledge projected back to wheat

The scientific purpose of Part B is to exploit the much deeper experimental
functional knowledge available for human and mouse—for example detailed
cellular machinery such as endoplasmic-reticulum, protein-folding, trafficking,
DNA-repair and related functions—to obtain additional **conserved-function
annotations for wheat genes**.

The analysis direction is:

```text
human/mouse experimentally supported GO
            ↓
human/mouse Ensembl gene
            ↓
direct OMA pairwise orthology
            ↓
wheat IWGSC RefSeq v2.1 gene
            ↓
animal-derived wheat gene→GO annotation
            ↓
wheat-space hypergeometric GO enrichment
```

The user still inputs wheat IDs, the enrichment background is still a wheat
gene universe, and the reported `geneID` column still contains wheat genes.
Human and mouse are analysed independently rather than merged before testing.

### Orthology mapping

TaeGO 1.1.0 uses **direct OMA pairwise orthology** as the primary animal–wheat
relationship. OMA explicitly represents 1:1, 1:n, m:1 and m:n pairwise
orthology; non-1:1 relationships are therefore retained rather than deleted by
an invented threshold.

Supporting routes through rice, maize and Arabidopsis are retained in the
mapping table as provenance/triangulation evidence, but relay-only endpoints do
not become direct wheat–mammal orthologs and a relay `rel_type` can never replace
the direct OMA `rel_type`.

The rebuilt mapping tables also retain OMA IDs and UniProt cross-references, but
the animal gene bridge is the corresponding Ensembl gene ID. The real rebuild
audit showed a one-to-one OMA-target→Ensembl-gene bridge for all mapped human
and mouse targets used in TaeGO 1.1.0.

### GO evidence policy

The publication-primary `experimental` projection uses:

```text
IDA, IEP, IGI, IMP, IPI
```

and excludes `GO:0005515` (`protein binding`). This annotation-quality subset
mirrors the experimentally supported source annotations used by GO
`GO_REF:0000107` for automatic orthology-based GO transfer. TaeGO does **not**
claim to reproduce that Ensembl-Compara pipeline: TaeGO uses OMA orthology and
does not import the Compara-specific 40% peptide-identity threshold.

A separate `allEvidence` output is retained as a reference/sensitivity view.
The historical broader 1.0.0 evidence workflow remains preserved in the
historical source archive for reproducibility, but is not an active 1.1.0 command.

### Enrichment parameters

After projection, the statistical object is again a wheat gene→GO table. TaeGO
therefore uses the same TGT-calibrated wheat-space ORA framework as Part A:

```text
hypergeometric ORA
BP / MF / CC independently
Benjamini-Hochberg within each GO aspect
minGSSize = 5
maxGSSize = 1200
FDR < 0.05
```

The default background for each species/evidence mode is all wheat genes having
at least one projected GO annotation in that mode. A user-supplied experimental
background is intersected with that projected-annotation universe.

### Interpretation boundary

Animal-derived GO projection is a **conserved-function annotation aid**, not
proof that wheat literally performs a human- or mouse-specific phenotype.
Mammal-specific labels must not be interpreted literally as wheat physiology.
The strongest interpretations emphasize conserved cellular and molecular
machinery. TaeGO 1.1.0 does not silently apply a custom taxon-constraint
blacklist because no frozen, version-matched taxon-constraint payload has yet
been added to the release.

## Main outputs

### Wheat

```text
<prefix>_all.csv
<prefix>_sig.csv
<prefix>_input_summary.tsv
<prefix>_unmapped_genes.txt
<prefix>_run_metadata.tsv
```

### Wheat-mammal

For each selected species and evidence view (`experimental`, `allEvidence`):

```text
<prefix>_<species>_<evidence>_all.csv
<prefix>_<species>_<evidence>_sig.csv
<prefix>_<species>_<evidence>_foreground_projected_gene2go.tsv
<prefix>_<species>_<evidence>_summary.tsv
<prefix>_<species>_<evidence>_unmapped_genes.txt
```

Mapping/provenance outputs:

```text
<prefix>_<species>_mapping_audit.tsv
<prefix>_<species>_relay_only.tsv
<prefix>_input_summary.tsv
<prefix>_run_metadata.tsv
```

Input lines are trimmed, blank lines removed and duplicate IDs collapsed.
Empty-but-valid result tables are written when an analysis completes normally
but no GO term is returned/significant.

## Validation and utility commands

```bash
taego -h
taego -v
taego doctor
taego info
taego validate
taego citation
```

`validate` checks required files, the release SHA256 manifest and data schemas.
`doctor` additionally checks required R/Bioconductor components. `info` reports
validated-reference versus actual runtime versions.

## Runtime reference

The TaeGO 1.1.0 validated-reference environment is frozen in
`environment.yml` and `manifest/runtime_versions.tsv`:

- R 4.4.1
- clusterProfiler 4.14.0
- GO.db 3.20.0
- dplyr 1.2.1
- org.Hs.eg.db 3.20.0
- org.Mm.eg.db 3.20.0
- AnnotationDbi 1.68.0
- GenomeInfoDbData 1.2.13

A version mismatch is reported for reproducibility; missing/unloadable required
packages fail `doctor`.

## Scientific documentation

See [`METHODS.md`](METHODS.md) for the evidence/parameter matrix and primary
references, [`docs/MAPPING_SCHEMA.md`](docs/MAPPING_SCHEMA.md) for the rebuilt
animal–wheat mapping contract, and [`INSTALL.md`](INSTALL.md) for installation.

`LICENSE` and `CITATION.cff` metadata are provided separately when available.

## Part B GO taxon-constraint QC

Final TaeGO 1.1.0 applies formal, version-pinned GO taxon-constraint QC after
direct OMA animal-to-wheat GO projection and before wheat-space ORA.

- Target taxon: *Triticum aestivum* (`NCBITaxon:4565`)
- GO taxon-constraint release: `2024-09-08`
- Bundled compatibility resource:
  `data/wheat_go_taxon_compatibility_2024-09-08.tsv`
- Resource SHA256:
  `61cdf7c9ec918e8c35f32315a6863454f4f61d8d4384aefecc572c7710adf95e`

`ALLOW` and `ALLOW_NO_CONSTRAINT` projected wheat-GO pairs are retained for
enrichment; `BLOCK_IN_TAXON` and `BLOCK_NEVER_IN_TAXON` pairs are excluded.
Unknown GO identifiers or unsupported compatibility states fail closed.

The raw orthology-derived projection is retained separately for provenance.
The filtered projection, not the raw projection, is used as the statistical
wheat gene-to-GO annotation universe.

