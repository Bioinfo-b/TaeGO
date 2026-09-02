#!/usr/bin/env Rscript
# ============================================================
# wheat_GO_enrichment.R
# TaeGO wheat module
# TGT-calibrated statistical framework + six-source wheat GO annotation
# ============================================================
# Annotation resource:
#   IWGSC official + InterProScan + eggNOG-mapper + GeneTribe
#   rice/maize/Arabidopsis 1-to-its-best homolog GO projections,
#   unified by GO ancestor propagation (true-path rule).
#
# Statistical settings retained from the archived TGT Single Sample
# calibration used for this project:
#   hypergeometric ORA; BP/MF/CC analysed separately; BH adjustment;
#   minGSSize=5; maxGSSize=1200; FDR<0.05.
#
# This is not an exact copy of TGT's historical annotation snapshot.
# ============================================================

suppressMessages({
  library(clusterProfiler)
  library(GO.db)
  library(dplyr)
  library(AnnotationDbi)
})

TAEGO_VERSION <- "1.1.0"
MIN_GS <- 5
MAX_GS <- 1200
FDR_CUTOFF <- 0.05

get_script_dir <- function() {
  a <- commandArgs(FALSE)
  m <- grep("^--file=", a, value = TRUE)
  if (length(m) > 0) return(dirname(normalizePath(sub("^--file=", "", m[1]))))
  getwd()
}

read_gene_list <- function(path) {
  raw <- readLines(path, warn = FALSE)
  cleaned <- trimws(raw)
  cleaned <- cleaned[!is.na(cleaned) & nzchar(cleaned)]
  unique_genes <- unique(cleaned)
  list(
    raw_count = length(raw),
    nonempty_count = length(cleaned),
    unique_count = length(unique_genes),
    duplicate_count = length(cleaned) - length(unique_genes),
    genes = unique_genes
  )
}

empty_result <- function() {
  data.frame(
    ONTOLOGY = character(),
    ID = character(),
    Description = character(),
    GeneRatio = character(),
    BgRatio = character(),
    pvalue = numeric(),
    p.adjust = numeric(),
    qvalue = numeric(),
    Count = integer(),
    geneID = character(),
    stringsAsFactors = FALSE
  )
}

safe_version <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) as.character(packageVersion(pkg)) else "MISSING"
}

write_kv_tsv <- function(path, keys, values) {
  df <- data.frame(metric = keys, value = as.character(values), stringsAsFactors = FALSE)
  write.table(df, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

DIR <- get_script_dir()
DATA_DIR <- normalizePath(file.path(DIR, "..", "data"), mustWork = TRUE)
ANNOT_FILE <- file.path(DATA_DIR, "wheat_union6_propagated_gene2go.tsv")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript wheat_GO_enrichment.R <foreground.txt> <output_prefix> [background.txt]")
}
fg_file <- args[1]
out_prefix <- args[2]
bg_file <- if (length(args) >= 3) args[3] else NA_character_

all_csv <- paste0(out_prefix, "_all.csv")
sig_csv <- paste0(out_prefix, "_sig.csv")
summary_tsv <- paste0(out_prefix, "_input_summary.tsv")
unmapped_txt <- paste0(out_prefix, "_unmapped_genes.txt")
metadata_tsv <- paste0(out_prefix, "_run_metadata.tsv")

cat("============================================\n")
cat("TaeGO wheat GO enrichment\n")
cat("TGT-calibrated statistics; six-source annotation\n")
cat("============================================\n")

cat("[1/5] Reading six-source propagated annotation...\n")
annot <- read.table(
  ANNOT_FILE,
  sep = "\t",
  quote = "",
  col.names = c("gene", "go"),
  stringsAsFactors = FALSE
)
annot <- annot %>% distinct(gene, go)
annot_genes <- unique(annot$gene)
cat(sprintf("      annotation: %d pairs, %d genes\n", nrow(annot), length(annot_genes)))

cat("[2/5] Resolving GO namespaces and names...\n")
go_info <- AnnotationDbi::select(
  GO.db,
  keys = unique(annot$go),
  columns = c("ONTOLOGY", "TERM"),
  keytype = "GOID"
)
ns_map <- c(BP = "biological_process", MF = "molecular_function", CC = "cellular_component")
go_info$namespace <- ns_map[go_info$ONTOLOGY]
annot <- annot %>%
  left_join(go_info, by = c("go" = "GOID")) %>%
  dplyr::filter(!is.na(namespace)) %>%
  distinct(gene, go, .keep_all = TRUE)

cat("[3/5] Reading foreground/background...\n")
fg_info <- read_gene_list(fg_file)
fg <- fg_info$genes

if (!is.na(bg_file)) {
  bg_info <- read_gene_list(bg_file)
  bg_requested <- bg_info$genes
  bg <- intersect(bg_requested, annot_genes)
  bg_source <- "custom"
  bg_raw_count <- bg_info$raw_count
  bg_unique_count <- bg_info$unique_count
  cat(sprintf("      custom background: %d unique input; %d annotated genes\n",
              bg_info$unique_count, length(bg)))
} else {
  bg <- annot_genes
  bg_source <- "all_annotated_wheat_genes"
  bg_raw_count <- NA_integer_
  bg_unique_count <- length(bg)
  cat(sprintf("      default background: %d annotated genes\n", length(bg)))
}

fg_in <- intersect(fg, bg)
unmapped <- setdiff(fg, bg)
writeLines(unmapped, unmapped_txt, useBytes = TRUE)
write_kv_tsv(
  summary_tsv,
  c(
    "foreground_raw_lines", "foreground_nonempty", "foreground_unique",
    "foreground_duplicates_removed", "foreground_mapped_to_effective_background",
    "foreground_unmapped", "background_source", "background_raw_lines",
    "background_unique_input_or_default", "background_effective_annotated"
  ),
  c(
    fg_info$raw_count, fg_info$nonempty_count, fg_info$unique_count,
    fg_info$duplicate_count, length(fg_in), length(unmapped), bg_source,
    bg_raw_count, bg_unique_count, length(bg)
  )
)
cat(sprintf("      foreground: %d unique; %d mapped; %d unmapped\n",
            length(fg), length(fg_in), length(unmapped)))

write_kv_tsv(
  metadata_tsv,
  c(
    "taego_version", "module", "annotation_resource", "statistical_test",
    "multiple_testing", "correction_scope", "min_gene_set_size",
    "max_gene_set_size", "fdr_cutoff", "R", "clusterProfiler", "GO.db",
    "dplyr", "AnnotationDbi"
  ),
  c(
    TAEGO_VERSION, "wheat", basename(ANNOT_FILE), "hypergeometric_ORA",
    "Benjamini-Hochberg", "BP_MF_CC_separate_TGT_calibrated", MIN_GS,
    MAX_GS, FDR_CUTOFF, as.character(getRversion()),
    safe_version("clusterProfiler"), safe_version("GO.db"), safe_version("dplyr"),
    safe_version("AnnotationDbi")
  )
)

if (length(fg_in) == 0) {
  write.csv(empty_result(), all_csv, row.names = FALSE)
  write.csv(empty_result(), sig_csv, row.names = FALSE)
  stop("No foreground genes are present in the effective annotated background; check wheat IWGSC RefSeq v2.1 gene IDs.")
}

cat("[4/5] Enrichment (minGSSize=5, maxGSSize=1200, BH within BP/MF/CC)...\n")
res_all <- list()
for (ns_val in c("biological_process", "molecular_function", "cellular_component")) {
  sub <- annot %>% dplyr::filter(namespace == ns_val)
  T2G <- sub %>% dplyr::select(go, gene) %>% distinct() %>% setNames(c("term", "gene"))
  T2N <- sub %>% dplyr::select(go, TERM) %>% distinct() %>% setNames(c("term", "name"))
  r <- enricher(
    fg_in,
    universe = bg,
    TERM2GENE = T2G,
    TERM2NAME = T2N,
    pvalueCutoff = 1,
    pAdjustMethod = "BH",
    minGSSize = MIN_GS,
    maxGSSize = MAX_GS,
    qvalueCutoff = 1
  )
  if (!is.null(r) && nrow(as.data.frame(r)) > 0) {
    df <- as.data.frame(r)
    df$ONTOLOGY <- c(
      biological_process = "BP",
      molecular_function = "MF",
      cellular_component = "CC"
    )[ns_val]
    res_all[[ns_val]] <- df
  }
}

if (length(res_all) == 0) {
  res <- empty_result()
} else {
  res <- bind_rows(res_all) %>%
    dplyr::select(
      ONTOLOGY, ID, Description, GeneRatio, BgRatio,
      pvalue, p.adjust, qvalue, Count, geneID
    ) %>%
    arrange(p.adjust)
}

cat("[5/5] Writing results...\n")
res_sig <- if (nrow(res) == 0) res else res %>% dplyr::filter(p.adjust < FDR_CUTOFF)
write.csv(res, all_csv, row.names = FALSE)
write.csv(res_sig, sig_csv, row.names = FALSE)

cat("============================================\n")
cat(sprintf("Completed: %d tested GO terms; %d significant at FDR<%.2f\n",
            nrow(res), nrow(res_sig), FDR_CUTOFF))
if (nrow(res) > 0) {
  cat(sprintf("  BP: %d (significant %d)\n", sum(res$ONTOLOGY == "BP"), sum(res_sig$ONTOLOGY == "BP")))
  cat(sprintf("  MF: %d (significant %d)\n", sum(res$ONTOLOGY == "MF"), sum(res_sig$ONTOLOGY == "MF")))
  cat(sprintf("  CC: %d (significant %d)\n", sum(res$ONTOLOGY == "CC"), sum(res_sig$ONTOLOGY == "CC")))
}
cat(sprintf("All results: %s\nSignificant results: %s\n", all_csv, sig_csv))
cat(sprintf("Input summary: %s\nUnmapped genes: %s\nRun metadata: %s\n",
            summary_tsv, unmapped_txt, metadata_tsv))
cat("============================================\n")
