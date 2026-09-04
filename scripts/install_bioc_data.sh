#!/usr/bin/env bash
# Install and verify Bioconductor data packages whose Conda post-link step
# may report success even when a network download was interrupted.
set -u

PREFIX="${CONDA_PREFIX:-}"
if [[ -z "$PREFIX" || ! -x "$PREFIX/bin/Rscript" ]]; then
  echo "ERROR: activate the TaeGO micromamba environment first." >&2
  echo "Example: micromamba activate taego" >&2
  exit 2
fi

LIB="$PREFIX/lib/R/library"
JSON="$PREFIX/share/bioconductor-data-packages/dataURLs.json"

if [[ ! -r "$JSON" ]]; then
  echo "ERROR: Bioconductor data metadata not found: $JSON" >&2
  echo "Recreate the environment from environment.yml and retry." >&2
  exit 1
fi

metadata_for() {
  local spec="$1"
  "$PREFIX/bin/Rscript" --vanilla - "$JSON" "$spec" <<'RSCRIPT'
args <- commandArgs(trailingOnly = TRUE)
path <- args[[1]]
spec <- args[[2]]

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("jsonlite is required to read Bioconductor data metadata")
}

data <- jsonlite::fromJSON(path, simplifyVector = FALSE)
item <- data[[spec]]

if (is.null(item)) {
  stop("metadata entry not found: ", spec)
}

cat(item$fn, "\n", sep = "")
cat(item$md5, "\n", sep = "")
for (url in item$urls) {
  cat(url, "\n", sep = "")
}
RSCRIPT
}

install_one() {
  local r_package="$1"
  local spec="$2"
  local -a meta urls

  mapfile -t meta < <(metadata_for "$spec")

  if [[ "${#meta[@]}" -lt 3 ]]; then
    echo "ERROR: incomplete metadata for $spec" >&2
    return 1
  fi

  local fn="${meta[0]}"
  local md5="${meta[1]}"
  urls=("${meta[@]:2}")

  local staging="$PREFIX/share/$spec"
  local tarball="$staging/$fn"

  if "$PREFIX/bin/Rscript" --vanilla -e \
      "quit(status = if (requireNamespace('$r_package', quietly=TRUE)) 0 else 1)"
  then
    echo "$r_package already available"
    return 0
  fi

  rm -rf -- "$staging"
  mkdir -p -- "$staging"

  local downloaded=0
  local url

  for url in "${urls[@]}"; do
    echo "Trying: $url"
    rm -f -- "$tarball"

    if curl -fL \
        --retry 5 \
        --retry-delay 5 \
        --retry-connrefused \
        --connect-timeout 30 \
        --max-time 1800 \
        -o "$tarball" "$url" &&
       printf '%s  %s\n' "$md5" "$tarball" | md5sum -c -
    then
      downloaded=1
      echo "Download and MD5 check passed"
      break
    fi

    echo "Download or MD5 check failed; trying next mirror" >&2
  done

  if [[ "$downloaded" -ne 1 ]]; then
    echo "ERROR: unable to obtain a verified tarball for $spec" >&2
    return 1
  fi

  "$PREFIX/bin/R" CMD INSTALL --library="$LIB" "$tarball"
  local rc=$?

  if [[ "$rc" -ne 0 ]]; then
    echo "ERROR: R CMD INSTALL failed for $r_package (rc=$rc)" >&2
    return "$rc"
  fi

  rm -rf -- "$staging"
  echo "Installed: $r_package"
  return 0
}

failed=0
install_one GenomeInfoDbData genomeinfodbdata-1.2.13 || failed=$((failed + 1))
install_one GO.db go.db-3.20.0 || failed=$((failed + 1))
install_one org.Hs.eg.db org.hs.eg.db-3.20.0 || failed=$((failed + 1))
install_one org.Mm.eg.db org.mm.eg.db-3.20.0 || failed=$((failed + 1))

if [[ "$failed" -ne 0 ]]; then
  echo "BIOC_DATA_INSTALL=FAIL packages=$failed" >&2
  exit 1
fi

"$PREFIX/bin/Rscript" --vanilla - <<'RSCRIPT'
pkgs <- c("GenomeInfoDbData", "GO.db", "org.Hs.eg.db", "org.Mm.eg.db")
failed <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]

if (length(failed)) {
  stop("Missing packages: ", paste(failed, collapse = ", "))
}

for (p in pkgs) {
  cat(p, "=", as.character(packageVersion(p)), "\n", sep = "")
}

cat("BIOC_DATA_INSTALL=PASS\n")
RSCRIPT
