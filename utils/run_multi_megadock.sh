#!/bin/sh

RECEPTOR_DIR="input/receptor"
LIGAND_DIR="input/ligand"
OUTPUT_DIR="output"
MEGADOCK_GPU="/usr/local/bin"
START_DIR=$(pwd)

find "$RECEPTOR_DIR" -name "*_sample*.pdb" -type f | while IFS= read -r receptor_file; do
    receptor=$(basename "$receptor_file" .pdb)

    find "$LIGAND_DIR" -name "*_sample*.pdb" -type f | while IFS= read -r ligand_file; do
        ligand=$(basename "$ligand_file" .pdb)

        PAIR_DIR="${OUTPUT_DIR}/${receptor}-${ligand}"
        mkdir -p "$PAIR_DIR"
        cd "$PAIR_DIR" || exit 1

        rm -f *.out
        megadock-gpu -R "$START_DIR/$receptor_file" -L "$START_DIR/$ligand_file"

        for out_file in *.out; do
            [ -e "$out_file" ] || continue

            rm -f Lgnd_Rot.pdb
            ${MEGADOCK_GPU}/decoygen Lgnd_Rot.pdb "$START_DIR/$ligand_file" "$out_file" 1

            sed -i -e 's/ A / Y /g' Lgnd_Rot.pdb

            head -n -2 "$START_DIR/$receptor_file" > "${receptor}-${ligand}-complex.pdb"
            cat Lgnd_Rot.pdb >> "${receptor}-${ligand}-complex.pdb"
        done

        cd "$START_DIR" || exit 1
    done
done
