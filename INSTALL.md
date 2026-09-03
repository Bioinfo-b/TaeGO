# TaeGO 1.1.0 installation guide

This guide is the authoritative installation procedure for TaeGO 1.1.0 on a
Linux x86_64 server. TaeGO is distributed as a release installer, while its R
and Bioconductor runtime is created separately from the frozen
`environment.yml` file.

## Before you start

TaeGO 1.1.0 supports Linux x86_64 and Bash. Ubuntu 22.04 or a compatible
distribution is the validated baseline. The server needs:

- Internet access for micromamba, Conda/Bioconductor packages, and the release
  download.
- `curl`, `tar`, `git`, and `sha256sum`.
- Sufficient disk space for the R/Bioconductor environment and TaeGO reference
  data.
- A writable installation prefix. Root is not required for a user-local
  installation.

Check the architecture and required tools:

```bash
uname -m
command -v curl tar git sha256sum
```

The architecture must be `x86_64`; if a required command is missing, install it
with the system package manager before continuing.

## Recommended path: ordinary user installation

This path installs micromamba and TaeGO under your user account and is the
recommended choice for a single user or a personal project account.

### Step 1 — Install micromamba

```bash
mkdir -p "$HOME/.local/bin"
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj -C "$HOME/.local/bin" --strip-components=1 bin/micromamba
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"
micromamba shell init --shell bash --root-prefix "$HOME/micromamba"
source "$HOME/.bashrc"
micromamba --version
```

If `micromamba` is already installed, start at Step 2 after activating its
shell integration.

### Step 2 — Obtain the frozen environment definition

Clone the public repository so that the exact environment file used below is
available locally:

```bash
git clone https://github.com/Bioinfo-b/TaeGO.git
cd TaeGO
```

Create and activate a dedicated environment. Do not install TaeGO's packages
into an unrelated analysis environment:

```bash
micromamba create -n taego-1.1.0 -f environment.yml -y
micromamba activate taego-1.1.0
```

The frozen runtime pins R 4.4.1 and the required Bioconductor packages. Confirm
that R is available:

```bash
R --version
Rscript --version
```

### Step 3 — Download the release installer

The v1.1.0 Release currently provides the Linux x86_64 installer and its SHA256
file. Download both files into a separate directory:

```bash
mkdir -p "$HOME/taego-downloads/1.1.0"
cd "$HOME/taego-downloads/1.1.0"
curl -LO https://github.com/Bioinfo-b/TaeGO/releases/download/v1.1.0/TaeGO-1.1.0-Linux-x86_64.sh
curl -LO https://github.com/Bioinfo-b/TaeGO/releases/download/v1.1.0/TaeGO-1.1.0-Linux-x86_64.sh.sha256
ls -lh TaeGO-1.1.0-Linux-x86_64.sh*
```

### Step 4 — Verify the installer before running it

Run the checksum check from the download directory:

```bash
sha256sum -c TaeGO-1.1.0-Linux-x86_64.sh.sha256
```

The expected result is:

```text
TaeGO-1.1.0-Linux-x86_64.sh: OK
```

If the result is not `OK`, do not run the installer. Delete the incomplete
download, download both files again, and repeat the check.

### Step 5 — Install into the active TaeGO environment

Keep the environment active and pass its prefix explicitly:

```bash
micromamba activate taego-1.1.0
bash TaeGO-1.1.0-Linux-x86_64.sh --prefix "$CONDA_PREFIX"
hash -r
```

The installer places the TaeGO launcher and its reference resources under the
selected prefix. It does not install micromamba, replace R, edit `/usr/local/bin`,
or silently modify shell startup files.

### Step 6 — Verify the installation

```bash
taego -v
taego doctor
taego validate
```

`doctor` checks the runtime packages and `validate` checks installed files,
checksums, and data schemas. Resolve any failure before running an analysis.

## Administrator path: system-wide deployment

Use this path when several server users should share one installation. An
administrator must create a shared, readable runtime prefix and keep it
writable during installation.

The commands below assume the administrator's `micromamba` executable is on
the `sudo` PATH. If micromamba is installed only for your own account, use its
absolute path or install/initialize it for the administrator account first.

The exact prefix is an administrator policy; the example below uses
`/opt/taego/1.1.0`. Replace it consistently if your site uses another path.

1. As an administrator, create a dedicated Conda/micromamba environment at the
   shared prefix using the repository's `environment.yml`:

   ```bash
   sudo mkdir -p /opt/taego/1.1.0
   sudo micromamba create -p /opt/taego/1.1.0 -f /path/to/TaeGO/environment.yml -y
   ```

2. Verify the checksum as an ordinary file check, then install into that same
   prefix:

   ```bash
   sha256sum -c TaeGO-1.1.0-Linux-x86_64.sh.sha256
   sudo bash TaeGO-1.1.0-Linux-x86_64.sh --prefix /opt/taego/1.1.0
   ```

3. Make the launcher available to users through a symlink:

   ```bash
   sudo ln -sfn /opt/taego/1.1.0/bin/taego /usr/local/bin/taego
   sudo chmod 755 /opt/taego/1.1.0
   ```

4. As each user, confirm that the shared runtime is readable and run:

   ```bash
   taego -v
   taego doctor
   taego validate
   ```

Do not use `chmod -R 755` on the installation tree. Directory traversal and
read permissions are required; data files do not need executable bits.

## First analysis

Create `genes.txt` with one canonical IWGSC RefSeq v2.1 wheat gene ID per line,
then run:

```bash
mkdir -p results
taego wheat -i genes.txt -o results/wheat_demo
```

For mammalian conserved-function projection:

```bash
taego wheat-mammal -i genes.txt -o results/human_demo -t human
taego wheat-mammal -i genes.txt -o results/mouse_demo -t mouse
```

See [docs/USAGE.md](docs/USAGE.md) for the input rules, output files, custom
backgrounds, and interpretation guidance.

## Upgrade and reproducibility

Keep each TaeGO release in its own environment or prefix. For a new release,
repeat the environment creation and checksum verification steps with the new
release files; do not overwrite a validated installation in place until the
new installation has passed `doctor` and `validate`.

Record these items with each analysis:

```bash
taego -v
taego info
taego validate
```

## Troubleshooting

### `micromamba: command not found`

In the current shell, restore the user-local path and shell hook:

```bash
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"
micromamba --version
```

### `taego: command not found`

Activate the environment used for installation and refresh the shell command
cache:

```bash
micromamba activate taego-1.1.0
hash -r
command -v taego
```

For a system-wide deployment, check both the symlink and directory traversal:

```bash
namei -l /usr/local/bin/taego
```

### `taego doctor` reports a missing package

The runtime was incomplete or a different environment is active. Check the
active prefix and recreate the dedicated environment from `environment.yml`:

```bash
echo "$CONDA_PREFIX"
micromamba env list
micromamba activate taego-1.1.0
taego doctor
```

### Checksum verification fails

Do not execute the installer. Re-download the installer and matching checksum
file from the [v1.1.0 Release](https://github.com/Bioinfo-b/TaeGO/releases/tag/v1.1.0)
and run `sha256sum -c` again.

### No genes are mapped

Confirm that the input is one wheat gene ID per line, has no header, and uses
the canonical IWGSC RefSeq v2.1 namespace. Inspect the generated
`*_input_summary.tsv` and `*_unmapped_genes.txt` files.

## Need help?

Please open an issue at
<https://github.com/Bioinfo-b/TaeGO/issues> and include the exact command,
`taego -v`, `taego info`, and the complete error message.

For micromamba command details, see the
[official micromamba documentation](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html).
