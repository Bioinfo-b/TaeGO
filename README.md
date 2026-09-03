# TaeGO

**TaeGO — Triticum aestivum Gene Ontology toolkit**

Version **1.1.0**

TaeGO is a Linux command-line bioinformatics toolkit for functional analysis of *Triticum aestivum* gene sets.

TaeGO provides two main analysis workflows:

1. **wheat** — wheat-focused GO enrichment analysis using an expanded wheat functional annotation resource.
2. **wheat-mammal** — conserved functional projection from human or mouse functional knowledge to wheat genes through direct OMA orthology, followed by wheat-space GO enrichment.

TaeGO is designed for wheat gene analysis. The input gene namespace and enrichment statistics remain in wheat gene space.

Human and mouse analyses are performed independently when multiple target species are selected.

## Download

The latest TaeGO release is available from GitHub Releases:

    https://github.com/Bioinfo-b/TaeGO/releases

Current release:

    TaeGO v1.1.0
    Platform: Linux x86_64
    Installer: TaeGO-1.1.0-Linux-x86_64.sh

SHA256 checksum verification is provided with the release assets.

## Installation

For complete installation instructions, see:

    INSTALL.md

The installation workflow includes:

1. Preparing the micromamba or conda runtime.
2. Creating the validated R/Bioconductor environment.
3. Installing the TaeGO release package.
4. Running doctor and validate checks.

## Quick start

### Wheat GO enrichment

Example:

    taego wheat -i genes.txt -o result

### Wheat-mammal conserved functional projection

Human and mouse functional knowledge can be projected to wheat genes through direct OMA orthology.

Examples:

    taego wheat-mammal -i genes.txt -o result -t human
    taego wheat-mammal -i genes.txt -o result -t mouse
    taego wheat-mammal -i genes.txt -o result -t both

The -t option selects the mammalian source species.

When both species are selected, human and mouse analyses remain independent.

## Analysis overview

### wheat workflow

The wheat workflow performs GO enrichment analysis using a wheat-focused functional annotation resource.

The workflow:

1. Accepts wheat gene IDs as input.
2. Builds a wheat gene-to-GO annotation table.
3. Performs GO over-representation analysis.
4. Reports biological categories enriched in the input gene set.

### wheat-mammal workflow

The wheat-mammal workflow uses experimentally supported human or mouse functional knowledge as an additional conserved-function annotation source.

Workflow direction:

    human/mouse functional knowledge
              ↓
       direct OMA orthology
              ↓
          wheat genes
              ↓
     wheat-space GO enrichment

The final enrichment statistics are performed in wheat gene space.

Animal-derived GO terms should be interpreted as conserved molecular or cellular functions, not as direct evidence of species-specific phenotypes.

## Main outputs

Wheat analysis outputs:

    <prefix>_all.csv
    <prefix>_sig.csv
    <prefix>_input_summary.tsv
    <prefix>_unmapped_genes.txt

Wheat-mammal analysis outputs include:

    enrichment result tables
    projected gene-to-GO annotation tables
    mapping audit files
    run summary files

## Validation commands

Useful TaeGO commands:

    taego -h
    taego -v
    taego doctor
    taego info
    taego validate

## Documentation

See the following files for more information:

    INSTALL.md   Installation instructions
    METHODS.md   Scientific methods and references
    docs/       Additional technical documentation
