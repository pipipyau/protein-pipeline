# The script for sharded-genetic-databases creating https://github.com/google-deepmind/alphafold3/blob/main/docs/performance.md#sharded-genetic-databases
# 0. Install seqkit https://github.com/shenwei356/seqkit

# 1. Shuffle the sequences in the fasta. This can be done for example by running: seqkit shuffle --two-pass <db.fasta>
# 2. Split the shuffled fasta in <SHARDS> shards. This can be done for example by running: seqkit split2 --by-part <s> <db.fasta>
SHARDS=16
PROTEIN_DBS=(
  mgy_clusters_2022_05.fa
  bfd-first_non_consensus_sequences.fasta
  uniref90_2022_05.fa
  uniprot_all_2021_04.fa
  pdb_seqres_2022_09_28.fasta
  rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta
)
RNA_DBS=(
  rnacentral_active_seq_id_90_cov_80_linclust.fasta
  nt_rna_2023_02_23_clust_seq_id_90_cov_80_rep_seq.fasta
)

for NAME in "${PROTEIN_DBS[@]}" "${RNA_DBS[@]}"; do
    echo "Shuffle ${NAME}"
    seqkit shuffle --two-pass "${NAME}" > "${NAME}.shuffled"

    echo "Split ${NAME} into ${SHARDS} shards"
    seqkit split2 --by-part ${SHARDS} "${NAME}.shuffled"
done

# 3. Rename shards
for NAME in "${PROTEIN_DBS[@]}" "${RNA_DBS[@]}"; do
    echo "Rename shards for ${NAME}"
    i=0
    for f in "${NAME}.shuffled.part_"*.fasta; do
        printf -v idx "%05d" "${i}"
        mv "$f" "${NAME}-${idx}-of-$(printf "%05d" ${SHARDS})"
        ((i++))
    done
done

# 4. Calculate Z-values (don't need this if export in 5th step)
# for NAME in "${PROTEIN_DBS[@]}"; do
#     echo "Z-value (protein) for ${NAME}"
#     seqkit stats "${NAME}" | tail -1 | awk '{print $4}'
# done

# for NAME in "${RNA_DBS[@]}"; do
#     echo "Z-value (RNA) for ${NAME}"
#     seqkit stats "${NAME}" | tail -1 | awk '{print $5}'
# done

# 5. Export flags
OUT_FILE="af3_sharded_db_flags.txt"
echo "# AlphaFold3 sharded database flags" > "${OUT_FILE}"
echo "# Generated on $(date)" >> "${OUT_FILE}"
echo >> "${OUT_FILE}"
echo "# Database flags" >> "${OUT_FILE}"

for NAME in "${PROTEIN_DBS[@]}"; do
    Z=$(seqkit stats "${NAME}" | tail -1 | awk '{print $4}')
    PREFIX="${NAME%@*}"

    echo "--${PREFIX}_database_path=${NAME}@${SHARDS} \\" >> "${OUT_FILE}"
    echo "--${PREFIX}_z_value=${Z} \\" >> "${OUT_FILE}"
    echo >> "${OUT_FILE}"
done

for NAME in "${RNA_DBS[@]}"; do
    Z=$(seqkit stats "${NAME}" | tail -1 | awk '{print $5}')
    PREFIX="${NAME%@*}"

    echo "--${PREFIX}_database_path=${NAME}@${SHARDS} \\" >> "${OUT_FILE}"
    echo "--${PREFIX}_z_value=${Z} \\" >> "${OUT_FILE}"
    echo >> "${OUT_FILE}"
done

echo "Flags written to ${OUT_FILE}"

# 5. Chekck the number of shards
# rm *.shuffled
# ls uniref90_2022_05.fa-* | wc -l
