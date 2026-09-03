# TaeGO 1.1.0 Methods and Evidence Contract

## 1. Overview

TaeGO is a wheat-focused Gene Ontology enrichment framework for *Triticum aestivum* gene sets.

TaeGO provides two analysis modes:

1. wheat: functional enrichment using a wheat gene-to-GO annotation resource.
2. wheat-mammal: conserved functional projection from human or mouse functional knowledge to wheat genes through direct OMA orthology.

Both workflows perform final enrichment analysis in wheat gene space.

The methods described here define the scientific scope, annotation sources, statistical framework and interpretation boundaries of TaeGO 1.1.0.

For installation and command examples, see [INSTALL.md](INSTALL.md) and
[docs/USAGE.md](docs/USAGE.md). This document records the analysis contract;
it is not a substitute for the user-facing installation guide.

## 2. Wheat GO enrichment framework

The wheat workflow performs Gene Ontology over-representation analysis using a wheat-focused gene-to-GO annotation resource.

The analysis workflow:

1. Input wheat gene identifiers are processed and mapped to wheat functional annotations.
2. Gene-to-GO relationships are constructed in wheat gene space.
3. GO enrichment is performed using hypergeometric over-representation analysis.
4. Biological categories are reported separately for Biological Process, Molecular Function and Cellular Component.

## 3. Wheat functional annotation resource

TaeGO uses an expanded wheat annotation resource assembled from multiple traceable sources:

- IWGSC RefSeq v2.1 functional annotation.
- InterProScan-derived functional annotation.
- eggNOG-mapper functional annotation.
- Rice, maize and Arabidopsis GO information transferred through 1-to-its-best homolog mapping.

These sources are combined at the wheat gene-to-GO level before enrichment analysis.

The expanded annotation resource is designed to increase functional coverage while maintaining source provenance.

## 4. GO term propagation

Positive GO annotations are expanded to parent GO terms using GO database hierarchy information.

This follows the Gene Ontology true-path interpretation, where annotations can contribute to more general biological categories through applicable parent relationships.

GO hierarchy information is obtained from GO.db within the validated Bioconductor runtime.

## 5. Statistical framework

TaeGO performs hypergeometric over-representation analysis for GO enrichment.

Statistical settings:

- Test: hypergeometric ORA.
- GO categories: Biological Process, Molecular Function and Cellular Component analyzed separately.
- Multiple testing correction: Benjamini-Hochberg correction.
- Gene-set size range: minGSSize 5 and maxGSSize 1200.
- Significance threshold: adjusted P value < 0.05.

The statistical unit of enrichment is the wheat gene-to-GO relationship table.

For experiments with a defined tested gene universe, users should provide an appropriate background set.

## 6. Wheat-mammal conserved functional projection

The wheat-mammal workflow transfers conserved functional knowledge from experimentally studied mammalian species to wheat genes.

The workflow direction is:

    human/mouse functional knowledge
              ↓
       direct OMA orthology
              ↓
          wheat genes
              ↓
     wheat-space GO enrichment

The final enrichment analysis remains in wheat gene space. Mammalian genes are not used as the statistical testing unit.

Human and mouse are analyzed independently. Selecting both species does not merge their GO annotation spaces before statistical testing.

## 7. OMA orthology mapping

TaeGO uses direct OMA pairwise orthology as the primary animal-wheat relationship source.

OMA relationship types including 1:1, 1:n, m:1 and m:n are retained as relationship information rather than filtered by an artificial sequence identity or coverage threshold.

Supporting plant routes are retained as provenance information only. Relay relationships do not create direct wheat-mammal orthology.

The mapping output preserves orthology provenance and identifier relationships used during functional projection.

## 8. GO evidence handling

Human and mouse GO annotations are obtained from validated Bioconductor OrgDb resources.

The primary conserved-function projection uses experimentally supported evidence categories:

    IDA, IEP, IGI, IMP, IPI

A separate allEvidence output can retain broader annotation evidence as a reference view.

The evidence selection is designed to prioritize experimentally supported functional knowledge during projection.

## 9. Interpretation boundary

Animal-derived GO projection represents conserved functional annotation support for wheat genes.

These annotations should not be interpreted as direct evidence that wheat possesses species-specific mammalian phenotypes.

The strongest interpretations concern conserved molecular and cellular functions shared across species.

TaeGO does not introduce arbitrary biological filtering rules without documented methodological support.

## 10. Runtime and software references

TaeGO 1.1.0 uses a frozen R/Bioconductor runtime defined in environment.yml.

The environment file pins the principal runtime packages used for validation;
it is not a complete lockfile for every transitive package. Record
`taego info` with each analysis.

Core software components include:

- clusterProfiler for enrichment analysis.
- GO.db for Gene Ontology hierarchy information.
- AnnotationDbi and organism annotation packages for functional annotation access.

## 11. References

- Yu G, Wang L-G, Han Y, He Q-Y. 2012. [clusterProfiler: an R Package for Comparing Biological Themes Among Gene Clusters](https://doi.org/10.1089/omi.2011.0118). *OMICS* 16:284-287.
- [Gene Ontology Consortium. Gene Ontology annotation and data resources](https://geneontology.org/docs/go-annotations/).
- Altenhoff AM et al. 2015. [The OMA orthology database in 2015: function predictions, better plant support, synteny view and other improvements](https://doi.org/10.1093/nar/gku1158). *Nucleic Acids Research* 43:D240-D249.
- Altenhoff AM et al. 2024. [OMA orthology in 2024](https://doi.org/10.1093/nar/gkad1020). *Nucleic Acids Research* 52:D513-D521.

The above references describe software, databases and comparative genomics resources used by TaeGO. TaeGO defines its own analysis workflow and functional projection framework.
