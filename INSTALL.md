# TaeGO 1.1.0 Installation

## 1. Platform and runtime model

TaeGO 1.1.0 targets Linux x86_64 (Ubuntu 22.04 compatibility baseline). The
installer contains the TaeGO application, scripts, data and metadata; it does
**not** bundle a complete R/Bioconductor runtime.

The validated-reference runtime is:

```text
R                      4.4.1
clusterProfiler        4.14.0
GO.db                  3.20.0
dplyr                   1.2.1
org.Hs.eg.db            3.20.0
org.Mm.eg.db            3.20.0
AnnotationDbi           1.68.0
GenomeInfoDbData        1.2.13
```

The same versions are frozen in `environment.yml` and
`manifest/runtime_versions.tsv`.

## 2. Create the runtime

With micromamba:

```bash
micromamba create -y \
  -p /path/to/taego/1.1.0 \
  -c conda-forge \
  -c bioconda \
  r-base=4.4.1 \
  bioconductor-clusterprofiler=4.14.0 \
  bioconductor-go.db=3.20.0 \
  r-dplyr=1.2.1 \
  bioconductor-org.hs.eg.db=3.20.0 \
  bioconductor-org.mm.eg.db=3.20.0 \
  bioconductor-annotationdbi=1.68.0 \
  bioconductor-genomeinfodbdata=1.2.13
```

A successful micromamba transaction is **not** the final installation
criterion. Bioconda annotation-data wrappers can be present in `conda-meta`
while the actual R annotation package payload is missing if their post-link
download failed.

## 3. Bioconductor annotation-data fallback

If the runtime later reports missing `GenomeInfoDbData`, `GO.db`,
`org.Hs.eg.db` or `org.Mm.eg.db`, first inspect the environment's own:

```text
<PREFIX>/share/bioconductor-data-packages/dataURLs.json
```

For the validated Bioconductor 3.20 runtime, the required data packages are:

```text
GenomeInfoDbData 1.2.13
GO.db             3.20.0
org.Hs.eg.db      3.20.0
org.Mm.eg.db      3.20.0
```

On the reference server, the standard download route intermittently returned
partial/EOF errors. The following Bioconductor mirror was successfully used:

```text
https://bioconductor.statistik.tu-dortmund.de/packages/3.20/data/annotation/src/contrib
```

Do not blindly download by filename alone. Read the URL/checksum record from
that environment's `dataURLs.json`, download the matching locked version, and
verify its checksum before installation. A robust download pattern is:

```bash
curl -fL \
  --connect-timeout 30 \
  --retry 5 \
  --retry-delay 3 \
  --retry-all-errors \
  -o PACKAGE.tar.gz \
  'https://bioconductor.statistik.tu-dortmund.de/packages/3.20/data/annotation/src/contrib/PACKAGE.tar.gz'
```

Then install with the **target environment's own R**:

```bash
/path/to/taego/1.1.0/bin/R CMD INSTALL \
  --library=/path/to/taego/1.1.0/lib/R/library \
  PACKAGE.tar.gz
```

The reference repair order that worked was:

```text
GenomeInfoDbData -> GO.db -> org.Hs.eg.db -> org.Mm.eg.db
```

Package load/version checks, not `conda-meta`, determine whether the repair
succeeded.

## 4. Install the TaeGO application

Into an existing runtime prefix:

```bash
bash TaeGO-1.1.0-Linux-x86_64.sh --prefix /path/to/taego/1.1.0
```

Or activate the intended conda/micromamba environment and omit `--prefix`.

The 1.1.0 installer performs:

```text
embedded payload extraction
-> SHA256 verification
-> staged copy
-> staged SHA256 verification
-> version-directory promotion
-> launcher installation last
```

It does not delete an existing same-version installation before a replacement
payload has passed integrity validation; failed promotion attempts restore the
previous same-version directory.

Installed layout:

```text
<PREFIX>/
├── bin/
│   └── taego
└── share/
    └── taego/
        └── 1.1.0/
            ├── bin/
            ├── scripts/
            ├── data/
            ├── manifest/
            ├── README.md
            ├── INSTALL.md
            ├── METHODS.md
            ├── CHANGELOG.md
            ├── environment.yml
            ├── SHA256SUMS
            └── VERSION
```

The installer does not edit `/usr/local/bin` or shell startup files.

## 5. Mandatory final verification

Run all three commands after installation:

```bash
/path/to/taego/1.1.0/bin/taego -v
/path/to/taego/1.1.0/bin/taego doctor
/path/to/taego/1.1.0/bin/taego validate
```

Expected version:

```text
TaeGO 1.1.0
```

Installation is not considered complete until the runtime is loadable and the
application/data checksums validate. `taego info` can additionally compare
actual package versions with the validated reference.

## 6. Optional administrator system-wide command

After the versioned installation is verified, an administrator can expose the
launcher globally:

```bash
ln -s "$TAEGO_PREFIX/bin/taego" /usr/local/bin/taego
```

This step is intentionally outside the installer. Writing to `/usr/local/bin`
normally requires administrator permission.

For a shared installation, ensure the installed application tree is readable
and traversable by intended users:

```bash
chmod -R a+rX "$TAEGO_PREFIX/share/taego/1.1.0"
```

## 7. Basic usage

```bash
taego wheat -i genes.txt -o result
taego wheat -i genes.txt -o result -b background.txt

taego wheat-mammal -i genes.txt -o result -t human
taego wheat-mammal -i genes.txt -o result -t mouse
taego wheat-mammal -i genes.txt -o result -t both
taego wheat-mammal -i genes.txt -o result -b background.txt -t human
```

See `README.md` and `METHODS.md` for scientific scope and output definitions.


