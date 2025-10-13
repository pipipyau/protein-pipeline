#!/bin/sh

RECEPTOR_DIR="input/receptor"  # /path/to/receptor/folder
LIGAND_DIR="input/ligand"      # /path/to/ligand/folder

for receptor in RBD_RSB_6LZG_unrelaxed_rank_001_alphafold2_ptm_model_4_seed_000 RBD_RSB_6LZG_unrelaxed_rank_002_alphafold2_ptm_model_3_seed_000 RBD_RSB_6LZG_unrelaxed_rank_003_alphafold2_ptm_model_5_seed_000 RBD_RSB_6LZG_unrelaxed_rank_004_alphafold2_ptm_model_2_seed_000 RBD_RSB_6LZG_unrelaxed_rank_005_alphafold2_ptm_model_1_seed_000
do
    for ligand in 6lzg-A_0_upd 6lzg-A_1_upd 6lzg-A_2_upd 6lzg-A_3_upd 6lzg-A_4_upd 6lzg-A_5_upd 6lzg-A_6_upd 6lzg-A_7_upd 6lzg-A_8_upd 6lzg-A_9_upd
    do
        mkdir ${receptor}_${ligand}
        cd ${receptor}_${ligand}
        
        cp ${RECEPTOR_DIR}/${receptor}.pdb ./
        cp ${LIGAND_DIR}/${ligand}.pdb ./
        
        for Rcpt in $(ls ${receptor}.pdb)
        do
            for Lgnd in $(ls ${ligand}.pdb)
            do
                rm -f *.out

                megadock-gpu -R ${Rcpt} -L ${Lgnd}
                
                for Out in $(ls *.out)
                do
                    rm -f Lgnd_Rot.pdb
                    ${MEGADOCK_GPU}/decoygen Lgnd_Rot.pdb ${Lgnd} ${Out} 1
                    
                    sed -i -e 's/ A / Y /g' ./Lgnd_Rot.pdb
                    head -n -2 ${Rcpt} > ${Rcpt}-${Lgnd}-complex.pdb
                    cat ./Lgnd_Rot.pdb >> ${Rcpt}-${Lgnd}-complex.pdb
                done
            done
        done
        
        cd ..
    done
done