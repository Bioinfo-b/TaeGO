#!/usr/bin/env Rscript
# ============================================================
# TaeGO 1.1.0 Part B: animal-derived conserved-function GO projection to wheat
#
# Scientific question (restored from the original Part B design):
#   use detailed human/mouse GO knowledge to annotate orthologous wheat genes,
#   then perform GO over-representation analysis in WHEAT gene space.
#
# Primary mapping:
#   direct OMA wheat <-> human/mouse pairwise orthology only.
#   1:1, 1:n, m:1 and m:n are preserved as OMA relation types; relay routes
#   (rice/maize/Arabidopsis) are retained as provenance/support but do not
#   create or upgrade primary direct orthology.
#
# Primary GO-transfer evidence policy:
#   IDA, IEP, IGI, IMP, IPI; GO:0005515 excluded. These restrictions mirror
#   the experimentally supported source-annotation subset used by the GOA
#   orthology-projection reference GO_REF:0000107. TaeGO uses OMA rather than
#   Ensembl Compara and therefore does NOT claim to reproduce that pipeline.
#
# Reference analysis:
#   allEvidence keeps all OrgDb GOALL associations as a sensitivity/reference
#   output. Human and mouse are analysed independently.
#
# Enrichment framework:
#   wheat-space hypergeometric ORA, BP/MF/CC separate BH correction,
#   minGSSize=5, maxGSSize=1200, FDR<0.05. These settings are the same
#   TGT-calibrated wheat-space enrichment framework used by TaeGO Part A.
#
# Historical preservation:
#   - TaeGO 1.0.0 Part B is preserved in scripts/partB_animal_projection_enrichment.R
#     and remains preserved in the TaeGO 1.0.0 legacy source archive.
#   - the temporary 1.1.0 XGSA candidate is preserved under docs/legacy/ and is
#     not the publication-primary Part B analysis.
#
# Usage (internal R interface):
#   Rscript wheat_mammal_conserved_function.R <foreground> <output_prefix>
#           [background|-] <human|mouse|both>
# ============================================================

suppressMessages({
  library(clusterProfiler)
  library(GO.db)
  library(dplyr)
  library(org.Hs.eg.db)
  library(org.Mm.eg.db)
  library(AnnotationDbi)
})

TAEGO_VERSION <- "1.1.0"
MIN_GS <- 5
MAX_GS <- 1200
FDR_CUTOFF <- 0.05
GOA_PRIMARY_CODES <- c("IDA","IEP","IGI","IMP","IPI")
PROTEIN_BINDING_GO <- "GO:0005515"
TAXON_GO_RELEASE <- "2024-09-08"
TARGET_TAXON <- "NCBITaxon:4565"
TAXON_COMPATIBILITY_FILE <- "wheat_go_taxon_compatibility_2024-09-08.tsv"
TAXON_COMPATIBILITY_SHA256 <- "61cdf7c9ec918e8c35f32315a6863454f4f61d8d4384aefecc572c7710adf95e"
GO_COMPUTED_TAXON_CONSTRAINTS_SHA256 <- "9b1ee1894fb6abc1e784326ea7c6dece211263b7173e31d0544d78d15c935856"
GO_TAXON_GROUPINGS_SHA256 <- "648cb63eccfb0ffc89073f0c5659adbba1640f37cc39ea9a6255a36e5be4611f"
WHEAT_NCBI_TAXONOMY_SHA256 <- "e22f0f7b21aabcf71f5967848115eb18be1d8c0dce21de45cb2ef2d43d031571"

get_script_dir <- function() {
  a <- commandArgs(FALSE)
  m <- grep("^--file=", a, value=TRUE)
  if (length(m) > 0) return(dirname(normalizePath(sub("^--file=", "", m[1]))))
  getwd()
}

read_gene_list <- function(path) {
  raw <- readLines(path, warn=FALSE)
  cleaned <- trimws(raw)
  cleaned <- cleaned[!is.na(cleaned) & nzchar(cleaned)]
  genes <- unique(cleaned)
  list(
    raw_count=length(raw),
    nonempty_count=length(cleaned),
    unique_count=length(genes),
    duplicate_count=length(cleaned)-length(genes),
    genes=genes
  )
}

as_flag <- function(x) {
  toupper(trimws(as.character(x))) %in% c("1","TRUE","T","YES","Y")
}

split_semicolon_ids <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) return(character())
  ids <- trimws(unlist(strsplit(x, ";", fixed=TRUE)))
  unique(ids[nzchar(ids)])
}

safe_version <- function(pkg) {
  if (requireNamespace(pkg, quietly=TRUE)) as.character(packageVersion(pkg)) else "MISSING"
}

write_kv_tsv <- function(path, keys, values) {
  write.table(
    data.frame(metric=keys, value=as.character(values), stringsAsFactors=FALSE),
    path, sep="\t", quote=FALSE, row.names=FALSE
  )
}

empty_result <- function() {
  data.frame(
    ONTOLOGY=character(), ID=character(), Description=character(),
    GeneRatio=character(), BgRatio=character(), pvalue=numeric(),
    p.adjust=numeric(), qvalue=numeric(), Count=integer(), geneID=character(),
    stringsAsFactors=FALSE
  )
}

read_route_projection <- function(path) {
  raw <- read.table(path, header=TRUE, sep="\t", quote="", stringsAsFactors=FALSE,
                    check.names=FALSE, comment.char="")
  required <- c(
    "wheat_v21", "target_omaid", "target_ensembl_gene", "target_uniprot",
    "direct_present", "direct_rel_type", "rice_support", "rice_rel_type",
    "maize_support", "maize_rel_type", "arabidopsis_support",
    "arabidopsis_rel_type", "relay_support_n"
  )
  if (!all(required %in% colnames(raw))) {
    stop("Route-separated projection table has incompatible schema: ", basename(path))
  }

  expanded <- lapply(seq_len(nrow(raw)), function(i) {
    target_genes <- split_semicolon_ids(raw$target_ensembl_gene[i])
    if (length(target_genes) == 0) target_genes <- ""
    data.frame(
      wheat_v21=rep(raw$wheat_v21[i], length(target_genes)),
      target_ensembl_gene=target_genes,
      target_omaid=rep(raw$target_omaid[i], length(target_genes)),
      target_uniprot=rep(raw$target_uniprot[i], length(target_genes)),
      direct_present=rep(as_flag(raw$direct_present[i]), length(target_genes)),
      direct_rel_type=rep(raw$direct_rel_type[i], length(target_genes)),
      rice_support=rep(as_flag(raw$rice_support[i]), length(target_genes)),
      rice_rel_type=rep(raw$rice_rel_type[i], length(target_genes)),
      maize_support=rep(as_flag(raw$maize_support[i]), length(target_genes)),
      maize_rel_type=rep(raw$maize_rel_type[i], length(target_genes)),
      arabidopsis_support=rep(as_flag(raw$arabidopsis_support[i]), length(target_genes)),
      arabidopsis_rel_type=rep(raw$arabidopsis_rel_type[i], length(target_genes)),
      relay_support_n=rep(as.integer(raw$relay_support_n[i]), length(target_genes)),
      evidence_routes=if ("evidence_routes" %in% colnames(raw))
        rep(raw$evidence_routes[i], length(target_genes)) else rep("", length(target_genes)),
      stringsAsFactors=FALSE
    )
  })
  bind_rows(expanded) %>% distinct()
}

get_animal_go <- function(orgdb, evidence_mode) {
  keys_ens <- keys(orgdb, keytype="ENSEMBL")
  df <- AnnotationDbi::select(
    orgdb,
    keys=keys_ens,
    columns=c("GOALL","EVIDENCEALL","ONTOLOGYALL"),
    keytype="ENSEMBL"
  )
  df <- df[!is.na(df$ENSEMBL) & !is.na(df$GOALL) & !is.na(df$ONTOLOGYALL), ]
  g <- data.frame(
    target_ensembl_gene=df$ENSEMBL,
    GO=df$GOALL,
    EVIDENCE=df$EVIDENCEALL,
    ONTOLOGY=df$ONTOLOGYALL,
    stringsAsFactors=FALSE
  )

  if (evidence_mode == "experimental") {
    g <- g %>% dplyr::filter(EVIDENCE %in% GOA_PRIMARY_CODES, GO != PROTEIN_BINDING_GO)
  } else if (evidence_mode != "allEvidence") {
    stop("Unknown evidence mode: ", evidence_mode)
  }

  g %>% distinct()
}

build_projected_wheat_go <- function(route, animal_go) {
  # Only direct OMA pairwise orthology is used to create the primary annotation.
  # Relay routes are preserved in the provenance columns below but never create
  # primary projected annotations on their own.
  direct <- route %>%
    dplyr::filter(direct_present, nzchar(target_ensembl_gene)) %>%
    distinct()

  projected_full <- direct %>%
    inner_join(animal_go, by="target_ensembl_gene", relationship="many-to-many") %>%
    dplyr::select(
      wheat_v21, target_ensembl_gene, target_omaid, target_uniprot,
      direct_rel_type, rice_support, rice_rel_type, maize_support, maize_rel_type,
      arabidopsis_support, arabidopsis_rel_type, relay_support_n, evidence_routes,
      GO, EVIDENCE, ONTOLOGY
    ) %>%
    distinct()

  wheat_go <- projected_full %>%
    dplyr::select(wheat=wheat_v21, go=GO, ont=ONTOLOGY) %>%
    distinct()

  list(full=projected_full, wheat_go=wheat_go)
}

read_taxon_compatibility <- function(path) {
  if (!file.exists(path) || file.info(path)$size <= 0) {
    stop("Missing frozen taxon compatibility resource: ", path)
  }

  x <- read.table(
    path,
    header=TRUE,
    sep="\t",
    quote="",
    stringsAsFactors=FALSE,
    check.names=FALSE,
    comment.char=""
  )

  required <- c(
    "GO", "GO_name", "status", "constraint_details",
    "go_release", "target_taxon"
  )

  if (!all(required %in% colnames(x))) {
    stop("Frozen taxon compatibility resource has incompatible schema: ", path)
  }

  if (any(is.na(x$GO)) || any(!nzchar(trimws(x$GO)))) {
    stop("Frozen taxon compatibility resource contains empty GO identifiers")
  }

  if (anyDuplicated(x$GO)) {
    stop("Frozen taxon compatibility resource contains duplicate GO identifiers")
  }

  if (any(x$go_release != TAXON_GO_RELEASE)) {
    stop(
      "Frozen taxon compatibility resource GO release mismatch; expected ",
      TAXON_GO_RELEASE
    )
  }

  if (any(x$target_taxon != TARGET_TAXON)) {
    stop(
      "Frozen taxon compatibility resource target taxon mismatch; expected ",
      TARGET_TAXON
    )
  }

  supported_status <- c(
    "ALLOW",
    "ALLOW_NO_CONSTRAINT",
    "BLOCK_IN_TAXON",
    "BLOCK_NEVER_IN_TAXON"
  )

  bad_status <- unique(x$status[!(x$status %in% supported_status)])

  if (length(bad_status) > 0) {
    stop(
      "unsupported taxon compatibility status in frozen resource: ",
      paste(bad_status, collapse=",")
    )
  }

  x %>%
    dplyr::select(
      GO, GO_name, status, constraint_details, go_release, target_taxon
    ) %>%
    distinct()
}

apply_taxon_compatibility <- function(projected, compatibility) {
  allowed_status <- c("ALLOW","ALLOW_NO_CONSTRAINT")

  raw_go <- unique(c(
    as.character(projected$full$GO),
    as.character(projected$wheat_go$go)
  ))

  raw_go <- raw_go[
    !is.na(raw_go) &
    nzchar(trimws(raw_go))
  ]

  missing_go <- setdiff(raw_go, compatibility$GO)

  if (length(missing_go) > 0) {
    stop(
      "GO term(s) missing from frozen taxon compatibility resource: ",
      paste(head(sort(missing_go), 20), collapse=","),
      if (length(missing_go) > 20) " ..." else ""
    )
  }

  used_status <- compatibility$status[
    match(raw_go, compatibility$GO)
  ]

  bad_status <- unique(
    used_status[
      is.na(used_status) |
      !(used_status %in% c(
        "ALLOW",
        "ALLOW_NO_CONSTRAINT",
        "BLOCK_IN_TAXON",
        "BLOCK_NEVER_IN_TAXON"
      ))
    ]
  )

  if (length(bad_status) > 0) {
    stop(
      "unsupported taxon compatibility status encountered during projection"
    )
  }

  full_status <- compatibility %>%
    dplyr::select(
      GO,
      taxon_status=status
    )

  wheat_status <- compatibility %>%
    dplyr::select(
      go=GO,
      taxon_status=status
    )

  annotated_full <- projected$full %>%
    left_join(
      full_status,
      by="GO",
      relationship="many-to-one"
    )

  annotated_wheat_go <- projected$wheat_go %>%
    left_join(
      wheat_status,
      by="go",
      relationship="many-to-one"
    )

  if (any(is.na(annotated_full$taxon_status)) ||
      any(is.na(annotated_wheat_go$taxon_status))) {
    stop("GO term(s) missing from frozen taxon compatibility resource")
  }

  filtered_full <- annotated_full %>%
    dplyr::filter(taxon_status %in% allowed_status) %>%
    dplyr::select(-taxon_status) %>%
    distinct()

  filtered_wheat_go <- annotated_wheat_go %>%
    dplyr::filter(taxon_status %in% allowed_status) %>%
    dplyr::select(-taxon_status) %>%
    distinct()

  list(
    raw_full = projected$full,
    raw_wheat_go = projected$wheat_go,
    taxon_full = annotated_full,
    taxon_wheat_go = annotated_wheat_go,
    full = filtered_full,
    wheat_go = filtered_wheat_go
  )
}


build_taxon_filter_audit <- function(projected) {
  formal_status <- c(
    "ALLOW",
    "ALLOW_NO_CONSTRAINT",
    "BLOCK_IN_TAXON",
    "BLOCK_NEVER_IN_TAXON"
  )

  provenance_counts <- projected$taxon_full %>%
    dplyr::count(
      taxon_status,
      name = "projection_rows_with_provenance"
    )

  pair_counts <- projected$taxon_wheat_go %>%
    dplyr::group_by(taxon_status) %>%
    dplyr::summarise(
      projected_wheat_GO_pairs = dplyr::n(),
      projected_wheat_genes = dplyr::n_distinct(wheat),
      GO_terms = dplyr::n_distinct(go),
      .groups = "drop"
    )

  audit <- data.frame(
    taxon_status = formal_status,
    stringsAsFactors = FALSE
  ) %>%
    dplyr::left_join(
      provenance_counts,
      by = "taxon_status",
      relationship = "one-to-one"
    ) %>%
    dplyr::left_join(
      pair_counts,
      by = "taxon_status",
      relationship = "one-to-one"
    )

  count_columns <- c(
    "projection_rows_with_provenance",
    "projected_wheat_GO_pairs",
    "projected_wheat_genes",
    "GO_terms"
  )

  for (column in count_columns) {
    audit[[column]][is.na(audit[[column]])] <- 0L
    audit[[column]] <- as.integer(audit[[column]])
  }

  audit
}

run_wheat_space_ora <- function(wheat_go, foreground, background_requested=NULL) {
  if (nrow(wheat_go) == 0) return(list(all=empty_result(), background=character(), foreground=character()))

  annotated_wheat <- unique(wheat_go$wheat)
  bg_use <- if (is.null(background_requested)) annotated_wheat else intersect(background_requested, annotated_wheat)
  fg_use <- intersect(foreground, bg_use)

  if (length(fg_use) == 0 || length(bg_use) == 0) {
    return(list(all=empty_result(), background=bg_use, foreground=fg_use))
  }

  go_name <- AnnotationDbi::select(
    GO.db, keys=unique(wheat_go$go), columns="TERM", keytype="GOID"
  )

  res_all <- list()
  for (o in c("BP","MF","CC")) {
    sub <- wheat_go %>% dplyr::filter(ont == o)
    if (nrow(sub) == 0) next
    T2G <- sub %>% dplyr::select(go, wheat) %>% distinct() %>% setNames(c("term","gene"))
    T2N <- go_name %>% dplyr::filter(GOID %in% sub$go) %>%
      dplyr::select(GOID, TERM) %>% distinct() %>% setNames(c("term","name"))
    r <- enricher(
      gene=fg_use,
      universe=bg_use,
      TERM2GENE=T2G,
      TERM2NAME=T2N,
      pvalueCutoff=1,
      pAdjustMethod="BH",
      minGSSize=MIN_GS,
      maxGSSize=MAX_GS,
      qvalueCutoff=1
    )
    if (!is.null(r) && nrow(as.data.frame(r)) > 0) {
      d <- as.data.frame(r)
      d$ONTOLOGY <- o
      res_all[[o]] <- d
    }
  }

  if (length(res_all) == 0) {
    res <- empty_result()
  } else {
    res <- bind_rows(res_all) %>%
      dplyr::select(ONTOLOGY, ID, Description, GeneRatio, BgRatio,
                    pvalue, p.adjust, qvalue, Count, geneID) %>%
      arrange(p.adjust, pvalue, ID)
  }
  list(all=res, background=bg_use, foreground=fg_use)
}

write_result_pair <- function(res, all_path, sig_path) {
  sig <- if (nrow(res) == 0) res else res %>% dplyr::filter(!is.na(p.adjust), p.adjust < FDR_CUTOFF)
  write.csv(res, all_path, row.names=FALSE)
  write.csv(sig, sig_path, row.names=FALSE)
  nrow(sig)
}

DIR <- get_script_dir()
DATA_DIR <- normalizePath(file.path(DIR, "..", "data"), mustWork=TRUE)

taxon_compatibility <- read_taxon_compatibility(
  file.path(DATA_DIR, TAXON_COMPATIBILITY_FILE)
)

args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript wheat_mammal_conserved_function.R <foreground> <output_prefix> [background|-] <human|mouse|both>")
}
fg_file <- args[1]
out_prefix <- args[2]
bg_arg <- if (length(args) >= 3) args[3] else "-"
target_arg <- if (length(args) >= 4) args[4] else "both"
if (!(target_arg %in% c("human","mouse","both"))) stop("target must be human, mouse, or both")
selected_targets <- if (target_arg == "both") c("human","mouse") else target_arg

fg_info <- read_gene_list(fg_file)
foreground <- fg_info$genes
if (bg_arg != "-" && nzchar(bg_arg)) {
  bg_info <- read_gene_list(bg_arg)
  background_requested <- bg_info$genes
  background_mode <- "custom"
} else {
  bg_info <- NULL
  background_requested <- NULL
  background_mode <- "all_wheat_genes_with_projected_GO_per_species_and_evidence_mode"
}

write_kv_tsv(
  paste0(out_prefix, "_input_summary.tsv"),
  c("foreground_raw_lines","foreground_nonempty","foreground_unique","foreground_duplicates_removed","background_mode"),
  c(fg_info$raw_count, fg_info$nonempty_count, fg_info$unique_count, fg_info$duplicate_count, background_mode)
)

write_kv_tsv(
  paste0(out_prefix, "_run_metadata.tsv"),
  c(
    "taego_version","module","scientific_question","primary_mapping","relay_policy",
    "target_statistical_unit","projection_evidence_primary","projection_excluded_term_primary",
    "reference_evidence_mode","statistical_test","multiple_testing","correction_scope",
    "min_gene_set_size","max_gene_set_size","fdr_cutoff",
        "taxon_qc",
        "target_taxon",
        "go_taxon_release",
        "taxon_compatibility_file",
        "taxon_compatibility_sha256",
        "go_computed_taxon_constraints_sha256",
        "go_taxon_groupings_sha256",
        "wheat_ncbi_taxonomy_sha256",
        "targets",
    "R","clusterProfiler","GO.db","org.Hs.eg.db","org.Mm.eg.db","AnnotationDbi"
  ),
  c(
    TAEGO_VERSION,"wheat-animal-projection",
    "animal_GO_projected_to_orthologous_wheat_then_wheat_space_ORA",
    "direct_OMA_pairwise_orthologs","relay_support_only_not_primary_projection",
    "wheat_gene","IDA|IEP|IGI|IMP|IPI",PROTEIN_BINDING_GO,
    "allEvidence","hypergeometric_ORA","Benjamini-Hochberg","BP_MF_CC_separate_TGT_calibrated",
    MIN_GS,MAX_GS,FDR_CUTOFF,
        "enabled",
        TARGET_TAXON,
        TAXON_GO_RELEASE,
        TAXON_COMPATIBILITY_FILE,
        TAXON_COMPATIBILITY_SHA256,
        GO_COMPUTED_TAXON_CONSTRAINTS_SHA256,
        GO_TAXON_GROUPINGS_SHA256,
        WHEAT_NCBI_TAXONOMY_SHA256,
        paste(selected_targets, collapse = ","),
    as.character(getRversion()),safe_version("clusterProfiler"),safe_version("GO.db"),
    safe_version("org.Hs.eg.db"),safe_version("org.Mm.eg.db"),safe_version("AnnotationDbi")
  )
)

for (species in selected_targets) {
  cat(sprintf("[%s] reading route-separated OMA mapping...\n", species))
  route_path <- file.path(DATA_DIR, sprintf("wheat_mammal_%s_routes.tsv", species))
  if (!file.exists(route_path)) {
    stop("Missing required route-separated mapping table: ", route_path,
         ". Rebuild TaeGO 1.1 mammalian mappings before running this module.")
  }
  route <- read_route_projection(route_path)
  orgdb <- if (species == "human") org.Hs.eg.db else org.Mm.eg.db

  # Mapping audit for the user's foreground preserves direct and relay evidence.
  mapping_audit <- route %>% dplyr::filter(wheat_v21 %in% foreground) %>% distinct()
  write.table(mapping_audit, sprintf("%s_%s_mapping_audit.tsv", out_prefix, species),
              sep="\t", quote=FALSE, row.names=FALSE)

  relay_only <- mapping_audit %>% dplyr::filter(!direct_present, relay_support_n > 0)
  write.table(relay_only, sprintf("%s_%s_relay_only.tsv", out_prefix, species),
              sep="\t", quote=FALSE, row.names=FALSE)

  for (evidence_mode in c("experimental","allEvidence")) {
    cat(sprintf("[%s/%s] projecting animal GO to wheat...\n", species, evidence_mode))
    animal_go <- get_animal_go(orgdb, evidence_mode)
    projected_raw <- build_projected_wheat_go(route, animal_go)
    projected <- apply_taxon_compatibility(
      projected_raw,
      taxon_compatibility
    )


    taxon_audit <- build_taxon_filter_audit(projected)

    write.table(
      taxon_audit,
      sprintf(
        "%s_%s_%s_taxon_filter_audit.tsv",
        out_prefix,
        species,
        evidence_mode
      ),
      sep="\t",
      quote=FALSE,
      row.names=FALSE
    )

    raw_projected_wheat_GO_pairs <- nrow(projected$raw_wheat_go)
    taxon_allowed_wheat_GO_pairs <- nrow(projected$wheat_go)

    taxon_block_in_taxon_wheat_GO_pairs <- sum(
      projected$taxon_wheat_go$taxon_status == "BLOCK_IN_TAXON"
    )

    taxon_block_never_in_taxon_wheat_GO_pairs <- sum(
      projected$taxon_wheat_go$taxon_status == "BLOCK_NEVER_IN_TAXON"
    )

    taxon_blocked_wheat_GO_pairs <-
      taxon_block_in_taxon_wheat_GO_pairs +
      taxon_block_never_in_taxon_wheat_GO_pairs

    foreground_projection_raw <- projected$raw_full %>%
      dplyr::filter(wheat_v21 %in% foreground)

    write.table(
      foreground_projection_raw,
      sprintf(
        "%s_%s_%s_foreground_projected_gene2go_raw.tsv",
        out_prefix,
        species,
        evidence_mode
      ),
      sep="\t",
      quote=FALSE,
      row.names=FALSE
    )

    foreground_projection <- projected$full %>% dplyr::filter(wheat_v21 %in% foreground)
    write.table(
      foreground_projection,
      sprintf("%s_%s_%s_foreground_projected_gene2go.tsv", out_prefix, species, evidence_mode),
      sep="\t", quote=FALSE, row.names=FALSE
    )

    ora <- run_wheat_space_ora(projected$wheat_go, foreground, background_requested)
    all_path <- sprintf("%s_%s_%s_all.csv", out_prefix, species, evidence_mode)
    sig_path <- sprintf("%s_%s_%s_sig.csv", out_prefix, species, evidence_mode)
    n_sig <- write_result_pair(ora$all, all_path, sig_path)

    unmapped <- setdiff(foreground, ora$background)
    writeLines(unmapped, sprintf("%s_%s_%s_unmapped_genes.txt", out_prefix, species, evidence_mode), useBytes=TRUE)

    write_kv_tsv(
      sprintf("%s_%s_%s_summary.tsv", out_prefix, species, evidence_mode),
      c(
        "projection_rows_with_provenance",
        "raw_projection_rows_with_provenance",
        "raw_projected_wheat_GO_pairs",
        "taxon_allowed_wheat_GO_pairs",
        "taxon_blocked_wheat_GO_pairs",
        "taxon_block_in_taxon_wheat_GO_pairs",
        "taxon_block_never_in_taxon_wheat_GO_pairs",
        "projected_wheat_GO_pairs",
        "projected_wheat_genes",
        "effective_background_wheat_genes",
        "foreground_unique",
        "foreground_in_effective_background",
        "foreground_unmapped",
        "tested_GO_terms",
        "significant_GO_terms_FDR_lt_0.05"
      ),
      c(
        nrow(projected$full),
        nrow(projected$raw_full),
        raw_projected_wheat_GO_pairs,
        taxon_allowed_wheat_GO_pairs,
        taxon_blocked_wheat_GO_pairs,
        taxon_block_in_taxon_wheat_GO_pairs,
        taxon_block_never_in_taxon_wheat_GO_pairs,
        nrow(projected$wheat_go),
        length(unique(projected$wheat_go$wheat)),
        length(ora$background),
        length(foreground),
        length(ora$foreground),
        length(unmapped),
        nrow(ora$all),
        n_sig
      )
    )

    cat(sprintf(
      "  %s/%s: projected wheat-GO=%d, wheat genes=%d, foreground=%d/%d, tested=%d, significant=%d\n",
      species,evidence_mode,nrow(projected$wheat_go),length(unique(projected$wheat_go$wheat)),
      length(ora$foreground),length(foreground),nrow(ora$all),n_sig
    ))
  }
}

cat("TaeGO animal-derived wheat GO projection analysis completed.\n")
