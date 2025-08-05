#!/bin/bash

pdbs=("6M0J-A"  "7DQA-A"  "7F5H-A" "7WBL-A" "7XBF-A" "7XBG-A")

# Путь к данным
data_dir="/home/jovyan/protein-protein-docking/data/RBD_base/"

# Путь для результатов
output_dir="/home/shared/alyanova/RFdiffusion/results/"

# Цикл по всем буквам из списка
for pdb in "${pdbs[@]}"; do
    input_pdb="${data_dir}${pdb}.pdb"
    output_prefix="${output_dir}${pdb}"
    
    if [ -f "$input_pdb" ]; then
        echo "RFD for ${pdb}.pdb"
        
        ./scripts/run_inference.py \
            contigmap.length=10-20 \
            inference.input_pdb="$input_pdb" \
            inference.output_prefix="$output_prefix" \
            inference.num_designs=5 \
            contigmap.contigs=[10-20]
            
    else
        echo "Not found ${input_pdb}."
    fi
done

echo "Finish."