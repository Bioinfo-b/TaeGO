# Changelog

## 2.0.0

### Scientific workflow

- Added an official GO taxon-constraint filter to the wheat workflow.
- Removed only gene–GO pairs whose GO terms are explicitly blocked in the
  NCBI animal taxon lineage by a positive `RO:0002162` (`in_taxon`)
  constraint.
- Preserved plant-compatible, broadly conserved, and unconstrained GO
  annotations.
- Added an audit table for removed gene–GO pairs and a filtering summary for
  every wheat run.

### Validation

- Tested against the 5,722-gene wheat regression set that previously exposed
  animal-specific GO terms.
- No animal-exclusive GO terms remained in the final wheat enrichment tables.
- The filtering resource is frozen from the official GO taxon-compatibility
  snapshot dated 2024-09-08.

### Mammalian workflow

- Preserved the human/mouse conserved-function projection logic.
- Preserved direct OMA mapping, relay provenance, independent human and mouse
  analyses, and wheat-space enrichment.

### Runtime and packaging

- Updated the release version to 2.0.0.
- Retained the validated R 4.4.1 and Bioconductor 3.20 runtime specification.
- Added the wheat taxon-compatibility and animal-exclusive GO resources to the
  release data package.

## 1.1.0

### Scientific workflow

- Introduced the wheat-focused GO enrichment framework for *Triticum aestivum* gene analysis.
- Added conserved functional projection from human and mouse functional knowledge to wheat genes through direct OMA orthology.
- Added independent human and mouse analysis modes through the wheat-mammal workflow.

### Annotation and analysis

- Expanded wheat functional annotation using multiple traceable annotation sources.
- Added wheat gene-space GO enrichment analysis with documented statistical parameters.
- Added orthology provenance and mapping audit information for conserved-function projection.

### CLI and validation

- Added standardized input handling and analysis commands.
- Added doctor and validate commands for runtime and release integrity checks.
- Added checksum verification support for release installers.

### Packaging and documentation

- Updated installation documentation for end-user installation workflow.
- Updated scientific documentation describing TaeGO methods, references and interpretation boundaries.
- Updated runtime specification with the validated R/Bioconductor environment.
- Added a fresh-server installation path, usage guide, and repository checks.

## Previous versions

Previous releases remain available through Git history and release archives.
