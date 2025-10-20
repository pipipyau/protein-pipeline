
set -euo pipefail

readonly archive_dir=${1}
readonly db_dir=${2}

for cmd in wget tar zstd ; do
  if ! command -v "${cmd}" > /dev/null 2>&1; then
    echo "${cmd} is not installed. Please install it."
  fi
done

echo "Fetching databases to ${db_dir}"
mkdir -p "${db_dir}"

echo "Start Fetching and Untarring 'pdb_2022_09_28_mmcif_files.tar'"
tar --no-same-owner --no-same-permissions \
    --use-compress-program=zstd -xf - --directory="${db_dir}" "${archive_dir}/pdb_2022_09_28_mmcif_files.tar.zst" &

for NAME in mgy_clusters_2022_05.fa \
            bfd-first_non_consensus_sequences.fasta \
            uniref90_2022_05.fa uniprot_all_2021_04.fa \
            pdb_seqres_2022_09_28.fasta \
            rnacentral_active_seq_id_90_cov_80_linclust.fasta \
            nt_rna_2023_02_23_clust_seq_id_90_cov_80_rep_seq.fasta \
            rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta ; do
  echo "Start Fetching '${NAME}'"
  zstd -d "${archive_dir}/${NAME}.zst" -o "${db_dir}/${NAME}" &
done

wait
echo "Complete"
