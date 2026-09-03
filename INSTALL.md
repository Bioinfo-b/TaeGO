# TaeGO 1.1.0 Installation Guide

## 1. System requirements

TaeGO 1.1.0 is a Linux x86_64 command-line bioinformatics software.

Supported environment:

- Linux x86_64
- Bash shell
- micromamba or conda
- Internet access during runtime preparation

Recommended:

- Ubuntu 22.04 or compatible distributions


## 2. Runtime environment

TaeGO requires a validated R/Bioconductor runtime.

The frozen runtime is defined in:

    environment.yml

Required packages:

    R 4.4.1
    clusterProfiler 4.14.0
    GO.db 3.20.0
    dplyr 1.2.1
    org.Hs.eg.db 3.20.0
    org.Mm.eg.db 3.20.0
    AnnotationDbi 1.68.0
    GenomeInfoDbData 1.2.13

The TaeGO installer does not replace the R/Bioconductor runtime.

## 3. Create TaeGO runtime

Create the runtime environment from the frozen configuration:

    micromamba create -n taego -f environment.yml

Activate the environment:

    micromamba activate taego

Verify required packages:

    R --version

The runtime should provide the validated R/Bioconductor package versions listed above.

## 4. Install TaeGO release package

Download the latest Linux x86_64 installer from GitHub Releases:

    https://github.com/Bioinfo-b/TaeGO/releases

Example installer:

    TaeGO-1.1.0-Linux-x86_64.sh

Verify the installer checksum before installation:

    sha256sum -c TaeGO-1.1.0-Linux-x86_64.sh.sha256

Run the installer:

    bash TaeGO-1.1.0-Linux-x86_64.sh

The installer installs the TaeGO application, scripts and reference resources.

The R/Bioconductor runtime must already be prepared separately.

## 5. Verify installation

After installation, activate the TaeGO runtime and check the installation:

    taego doctor

Validate installed files and release integrity:

    taego validate

Check available commands:

    taego -h

Report version information:

    taego -v

## 6. Installation workflow summary

The complete installation workflow is:

1. Prepare micromamba or conda.
2. Create the validated R/Bioconductor runtime from environment.yml.
3. Download the TaeGO Linux x86_64 release installer.
4. Verify the SHA256 checksum.
5. Run the installer.
6. Run doctor and validate checks.
