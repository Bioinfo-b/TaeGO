# 🌾 TaeGO

**TaeGO — Triticum aestivum Gene Ontology toolkit**

Release **v1.1.0** · Linux x86_64

[![Latest release](https://img.shields.io/github/v/release/Bioinfo-b/TaeGO?display_name=tag&sort=semver)](https://github.com/Bioinfo-b/TaeGO/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64-informational)](https://github.com/Bioinfo-b/TaeGO)
[![Repository checks](https://github.com/Bioinfo-b/TaeGO/actions/workflows/repository-checks.yml/badge.svg)](https://github.com/Bioinfo-b/TaeGO/actions/workflows/repository-checks.yml)

TaeGO is a Linux command-line toolkit for Gene Ontology (GO) analysis of
*Triticum aestivum* gene sets. It keeps the final enrichment statistics in
wheat gene space and provides two workflows:

- **`taego wheat`** — wheat-focused GO enrichment using an expanded,
  provenance-traceable wheat annotation resource.
- **`taego wheat-mammal`** — projects experimentally supported human or mouse
  functional knowledge to wheat through direct OMA orthology, then performs
  enrichment in wheat gene space.

Human and mouse are analyzed independently when `--target both` is selected.

## 🚀 Install on a fresh Linux server

The commands below are the standard user-local installation path. They assume
an Ubuntu-like Linux x86_64 server and do not require root access.

### 1. Check the platform

```bash
uname -m
# Expected: x86_64
```

### 2. Install micromamba

```bash
mkdir -p "$HOME/.local/bin"
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj -C "$HOME/.local/bin" --strip-components=1 bin/micromamba
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"
micromamba shell init --shell bash --root-prefix "$HOME/micromamba"
source "$HOME/.bashrc"
```

### 3. Create the validated TaeGO environment

```bash
git clone https://github.com/Bioinfo-b/TaeGO.git
cd TaeGO
micromamba create -n taego-1.1.0 -f environment.yml -y
micromamba activate taego-1.1.0
```

### 4. Download, verify, and install TaeGO

```bash
mkdir -p "$HOME/taego-downloads/1.1.0"
cd "$HOME/taego-downloads/1.1.0"

curl -LO https://github.com/Bioinfo-b/TaeGO/releases/download/v1.1.0/TaeGO-1.1.0-Linux-x86_64.sh
curl -LO https://github.com/Bioinfo-b/TaeGO/releases/download/v1.1.0/TaeGO-1.1.0-Linux-x86_64.sh.sha256

sha256sum -c TaeGO-1.1.0-Linux-x86_64.sh.sha256
bash TaeGO-1.1.0-Linux-x86_64.sh --prefix "$CONDA_PREFIX"
hash -r
```

### 5. Verify the installation

```bash
taego -v
taego doctor
taego validate
```

All three checks should complete successfully before analysis. If you need a
system-wide installation for multiple users, follow the administrator section
in [INSTALL.md](INSTALL.md).

## ⚡ Quick start

### Wheat GO enrichment

Prepare a plain-text file containing one canonical wheat gene ID per line
(without a header), for example `genes.txt`, then run:

```bash
mkdir -p results
taego wheat -i genes.txt -o results/wheat_demo
```

Optional custom background:

```bash
taego wheat -i genes.txt -b background.txt -o results/wheat_with_background
```

### Wheat–mammal conserved-function projection

Run human and mouse independently:

```bash
taego wheat-mammal -i genes.txt -o results/mammal_human -t human
taego wheat-mammal -i genes.txt -o results/mammal_mouse -t mouse
```

Or run both analyses as separate outputs:

```bash
taego wheat-mammal -i genes.txt -o results/mammal_demo -t both
```

See [docs/USAGE.md](docs/USAGE.md) for input rules, output files, and common
examples.

## 📥 Input and 📤 output

Input files are one gene identifier per line. Empty lines and duplicate IDs are
handled by the analysis scripts; keep identifiers in the canonical IWGSC
RefSeq v2.1 wheat namespace. A background file, when supplied, must use the
same wheat identifier namespace.

Wheat runs commonly produce:

```text
<prefix>_all.csv
<prefix>_sig.csv
<prefix>_input_summary.tsv
<prefix>_unmapped_genes.txt
```

Mammal projection runs additionally produce projected annotation tables,
mapping audit files, and run summaries. The final statistical unit for both
workflows is the wheat gene.

## 🔧 Useful commands

```bash
taego -h
taego wheat -h
taego wheat-mammal -h
taego info
taego citation
```

## 📚 Documentation

- [INSTALL.md](INSTALL.md) — complete installation, administrator deployment,
  upgrade, and troubleshooting guide.
- [docs/USAGE.md](docs/USAGE.md) — input format, commands, outputs, and
  interpretation guide.
- [METHODS.md](METHODS.md) — scientific methods, annotation sources, and
  references.
- [docs/MAPPING_SCHEMA.md](docs/MAPPING_SCHEMA.md) — wheat–mammal mapping
  fields and provenance semantics.
- [CHANGELOG.md](CHANGELOG.md) — release history.

## 🧬 Scientific scope

The wheat workflow uses a six-source wheat gene-to-GO resource with GO
ancestor propagation and hypergeometric over-representation analysis. The
wheat–mammal workflow uses direct OMA relationships and experimentally
supported mammalian GO annotations as a conserved-function projection.

Animal-derived terms indicate conserved functional annotation support; they are
not evidence of a wheat-specific mammalian phenotype.

## Support

For a reproducible bug report, include the output of `taego -v`, `taego info`,
the exact command, and the relevant error message. Please open an issue at
<https://github.com/Bioinfo-b/TaeGO/issues>.
