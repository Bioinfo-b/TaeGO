#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILTER_FILE = ROOT / "data" / "wheat_animal_exclusive_go_2024-09-08.tsv"
FIXTURE_FILE = ROOT / "tests" / "fixtures" / "wheat_animal_go_genes.txt"

REQUIRED_COLUMNS = {
    "GO",
    "GO_name",
    "status",
    "constraint_details",
    "go_release",
    "target_taxon",
    "animal_constraint_taxa",
    "animal_constraint_names",
    "filter_rule",
}

EXPECTED_RULE = "BLOCK_IN_TAXON+RO:0002162+NCBI_animal_taxon"


def main():
    with FILTER_FILE.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))

    assert rows, "filter table is empty"
    assert REQUIRED_COLUMNS.issubset(rows[0]), "filter columns are incomplete"

    go_ids = [row["GO"] for row in rows]
    assert len(go_ids) == len(set(go_ids)), "GO IDs are duplicated"
    assert all(row["status"] == "BLOCK_IN_TAXON" for row in rows)
    assert all(row["filter_rule"] == EXPECTED_RULE for row in rows)
    assert "GO:0030594" in set(go_ids)

    with FIXTURE_FILE.open(encoding="utf-8") as handle:
        genes = [line.strip() for line in handle if line.strip()]

    assert len(genes) == 5722
    assert len(set(genes)) == 5722

    print(f"FILTER_GO_TERMS={len(rows)}")
    print(f"FIXTURE_GENES={len(set(genes))}")
    print("GO_0030594=PASS")
    print("ANIMAL_CONSTRAINT_SELECTION=PASS")


if __name__ == "__main__":
    main()
