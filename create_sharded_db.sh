#!/usr/bin/env bash
# The script for sharded-genetic-databases creating https://github.com/google-deepmind/alphafold3/blob/main/docs/performance.md#sharded-genetic-databases
# 0. Install seqkit https://github.com/shenwei356/seqkit
SEQKIT="/e/seqkit.exe"
# 1. Shuffle the sequences in the fasta. This can be done for example by running: seqkit shuffle --two-pass <db.fasta>
# 2. Split the shuffled fasta in <SHARDS> shards. This can be done for example by running: seqkit split2 --by-part <s> <db.fasta>
SHARDS=512 # To use different shards for every DB comment other in dbs lists below.

PROTEIN_DBS=(
  mgy_clusters_2022_05.fa
  bfd-first_non_consensus_sequences.fasta #SHARDS=64
  uniref90_2022_05.fa #SHARDS=128
  uniprot_all_2021_04.fa
  pdb_seqres_2022_09_28.fasta
  rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta
)
RNA_DBS=(
  rnacentral_active_seq_id_90_cov_80_linclust.fasta #SHARDS=3
  nt_rna_2023_02_23_clust_seq_id_90_cov_80_rep_seq.fasta
)

# Load env
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

if [[ -z "${AF_PUBLIC_DB_DIR:-}" ]]; then
    echo "AF_PUBLIC_DB_DIR is not set in .env"
    exit 1
fi

echo "Using AF_PUBLIC_DB_DIR=${AF_PUBLIC_DB_DIR}"

for NAME in "${PROTEIN_DBS[@]}" "${RNA_DBS[@]}"; do
    SRC="${AF_PUBLIC_DB_DIR}/${NAME}"
    BASENAME="${NAME%.*}"
    EXT="${NAME##*.}"
    SHUFFLED="${AF_PUBLIC_DB_DIR}/${BASENAME}.shuffled.${EXT}"

    echo "Shuffle ${NAME}"
    "${SEQKIT}" shuffle --two-pass "${SRC}" > "${SHUFFLED}"

    echo "Split ${NAME} into ${SHARDS} shards"
    (
      cd "${AF_PUBLIC_DB_DIR}"
      "${SEQKIT}" split2 --by-part ${SHARDS} "$(basename "${SHUFFLED}")"
    )
done

# 3. Rename shards
for NAME in "${PROTEIN_DBS[@]}" "${RNA_DBS[@]}"; do
    BASENAME="${NAME%.*}"
    EXT="${NAME##*.}"
    SHUFFLED="${AF_PUBLIC_DB_DIR}/${BASENAME}.shuffled.${EXT}"

    echo "Rename shards for ${NAME}"
    i=0
    for f in "${SHUFFLED}.split/${BASENAME}.shuffled.part_"*.fasta; do
        printf -v idx "%05d" "${i}"
        printf -v total "%05d" "${SHARDS}"
        mv "$f" "${AF_PUBLIC_DB_DIR}/${NAME}-${idx}-of-${total}"
        ((i++))
    done
done

# 5. Calculate Z-values and export flags
OUT_FILE="${AF_PUBLIC_DB_DIR}/af3_sharded_db_flags.txt"
echo >> "${OUT_FILE}"
echo "# Database flags" >> "${OUT_FILE}"

# Protein
for NAME in "${PROTEIN_DBS[@]}"; do
    Z=$("${SEQKIT}" stats "${AF_PUBLIC_DB_DIR}/${NAME}" | tail -1 | awk '{print $4}')
    PREFIX="${NAME%@*}"

    echo "--${PREFIX}_database_path=${AF_PUBLIC_DB_DIR}/${NAME}@${SHARDS} \\" >> "${OUT_FILE}"
    echo "--${PREFIX}_z_value=${Z} \\" >> "${OUT_FILE}"
    echo >> "${OUT_FILE}"
done

# RNA
for NAME in "${RNA_DBS[@]}"; do
    Z=$("${SEQKIT}" stats "${AF_PUBLIC_DB_DIR}/${NAME}" | tail -1 | awk '{print $5}')
    PREFIX="${NAME%@*}"

    echo "--${PREFIX}_database_path=${AF_PUBLIC_DB_DIR}/${NAME}@${SHARDS} \\" >> "${OUT_FILE}"
    echo "--${PREFIX}_z_value=${Z} \\" >> "${OUT_FILE}"
    echo >> "${OUT_FILE}"
done

echo "Flags written to ${OUT_FILE}"
# echo
# echo "Press Enter to exit"
# read