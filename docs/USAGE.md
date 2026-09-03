# TaeGO usage guide

This guide assumes TaeGO 1.1.0 is installed and the runtime environment is
active. If you have not installed TaeGO yet, follow [INSTALL.md](../INSTALL.md)
first.

## 1. Prepare the input

Create a UTF-8 plain-text file with one canonical IWGSC RefSeq v2.1 wheat gene
ID per line. Do not add a header or extra columns.

```text
<wheat_gene_id_1>
<wheat_gene_id_2>
<wheat_gene_id_3>
```

Save the file as `genes.txt`. A custom background file uses the same format and
must represent the tested wheat gene universe.

Empty lines and duplicate IDs are handled by the analysis scripts. IDs that do
not occur in the TaeGO annotation resource are reported in the unmapped-gene
output instead of being silently counted as mapped genes.

## 2. Wheat GO enrichment

Run the wheat-focused workflow with:

```bash
mkdir -p results
taego wheat -i genes.txt -o results/wheat_demo
```

Use a custom background when the experiment has a defined tested universe:

```bash
taego wheat \
  --input genes.txt \
  --background background.txt \
  --output results/wheat_with_background
```

The default background is the annotated TaeGO wheat universe. A supplied
background is intersected with that annotated universe before testing.

## 3. Wheat–mammal conserved-function projection

The mammal workflow projects human or mouse functional annotations through
direct OMA wheat–mammal orthology and then performs enrichment in wheat gene
space.

Run one source species:

```bash
taego wheat-mammal -i genes.txt -o results/human_demo -t human
taego wheat-mammal -i genes.txt -o results/mouse_demo -t mouse
```

Run both species as independent analyses:

```bash
taego wheat-mammal -i genes.txt -o results/mammal_demo -t both
```

`human` and `mouse` results are not pooled into one statistical test. Relay
routes through rice, maize, or Arabidopsis are retained as provenance and do
not replace direct OMA relationships.

## 4. Command reference

| Command | Purpose |
| --- | --- |
| `taego wheat -i GENES -o PREFIX` | Wheat GO enrichment |
| `taego wheat -i GENES -b BACKGROUND -o PREFIX` | Wheat enrichment with a custom background |
| `taego wheat-mammal -i GENES -o PREFIX -t human` | Human-derived conserved-function projection |
| `taego wheat-mammal -i GENES -o PREFIX -t mouse` | Mouse-derived conserved-function projection |
| `taego wheat-mammal -i GENES -o PREFIX -t both` | Independent human and mouse analyses |
| `taego doctor` | Check runtime packages and installed files |
| `taego info` | Show the installed root and runtime versions |
| `taego validate` | Check files, checksums, and data schemas |
| `taego citation` | Show citation guidance |

Use `taego wheat -h` and `taego wheat-mammal -h` to display the exact options
available in the installed version.

## 5. Output files

For a wheat run with prefix `results/wheat_demo`, the main outputs are:

| File | Meaning |
| --- | --- |
| `results/wheat_demo_all.csv` | All tested GO terms and statistics |
| `results/wheat_demo_sig.csv` | Terms passing the adjusted P-value threshold |
| `results/wheat_demo_input_summary.tsv` | Input, mapped, and background summary |
| `results/wheat_demo_unmapped_genes.txt` | Input IDs not mapped to the annotation resource |

Mammal runs additionally write projected gene-to-GO tables, mapping audit
files, and run summaries. Keep the complete output directory with the command
and version record for reproducibility.

## 6. How enrichment is interpreted

GO enrichment is performed separately for Biological Process, Molecular
Function, and Cellular Component using hypergeometric over-representation
analysis with Benjamini–Hochberg correction. The documented gene-set range is
5–1200 and the reported significance threshold is adjusted P value `< 0.05`.

Animal-derived terms represent conserved functional annotation support in wheat.
They are not direct evidence that wheat has a mammalian-specific phenotype.

## 7. Record a run

Before or after an analysis, record the installed software and runtime:

```bash
taego -v
taego info
taego validate
```

For support, include these outputs, the exact input/background command, and the
complete error message in a GitHub issue.
