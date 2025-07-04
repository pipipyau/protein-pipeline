# RFdiffusion Protein Design & Docking Pipeline

![Bioinformatics Pipeline](https://img.shields.io/badge/pipeline-protein_design-blue)
![License](https://img.shields.io/badge/license-MIT-green)

This pipeline combines RFdiffusion for protein design with MEGADOCK for protein docking and Prodigy for binding affinity calculations.

## Table of Contents
1. [Protein Design with RFdiffusion](#1-protein-design-with-rfdiffusion)
2. [Protein Docking with MEGADOCK](#2-protein-docking-with-megadock)
3. [Binding Affinity Calculation](#3-binding-affinity-calculation)

---

## 1. Protein Design with RFdiffusion

Design protein aptamers using RFdiffusion:

```bash
./scripts/run_inference.py \
  'contigmap.contigs=[8-30/A31-41/8-30]' \
  contigmap.length=8-30 \
  inference.input_pdb=/path/to/input_pdb/6lzg-A.pdb \
  inference.output_prefix=/path/to/outputs/6lzg-A \
  inference.num_designs=10
```
---

## 2. Protein Docking with MEGADOCK

### Installation
Requires MEGADOCK-GPU (non-MPI version):
```bash
git clone https://github.com/akiyamalab/MEGADOCK
```
**Important:** Use GCC 10 (specify in Makefile):
```makefile
NVCC := $(CUDA_INSTALL_PATH)/bin/nvcc -Xcompiler -fopenmp -arch=$(SM_VERSIONS) -use_fast_math -ccbin=g++-10
```

### Preprocessing
RFdiffusion outputs need reformatting (PDB line length < 80 chars):
```bash
python ./util_scripts/fix_pdb.py
```

### Running Docking
```bash
sudo ./util_scripts/script_multi_dock.sh
```

**Output:**  
Complex files named `*-complex.pdb` where:
- Receptor chains retain original names (A, B, C...)
- Ligand chains (designed aptamers) are renamed to Y

---

## 3. Binding Affinity Calculation

### Setup Prodigy
```bash
python -m venv ./venv
source ./venv/bin/activate
pip install prodigy-prot
```

### Calculation Script
```bash
#!/bin/bash
# ./util_scripts/script_affinity.sh

OUTPUT_FILE="prodigy_results.txt"
> "$OUTPUT_FILE"

for pdb in $(find . -name *-complex.pdb); do
  echo "===== Calculating for $pdb =====" >> "$OUTPUT_FILE"
  prodigy "$pdb" --selection A Y >> "$OUTPUT_FILE" 2>&1
  echo "" >> "$OUTPUT_FILE"
done
```

**Usage:**
```bash
chmod +x script_affinity.sh
./script_affinity.sh
```

**Output Analysis:**  
The results in `prodigy_results.txt` can be used for binding affinity analysis and visualization.

---

## Pipeline Overview
```mermaid
graph TD
    A[RFdiffusion Design] --> B[PDB Format Fix]
    B --> C[MEGADOCK Docking]
    C --> D[Prodigy Affinity]
    D --> E[Analysis]
```
