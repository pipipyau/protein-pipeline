#!/bin/sh

INPUT_DIR="input"
OUTPUT_FILE="output/prodigy_results.txt"

> "$OUTPUT_FILE"

find "$INPUT_DIR" -type f -name "*-complex.pdb" | while read -r pdb; do
  echo "===== Calculating for $pdb ====="
  prodigy "$pdb" --selection A Y >> "$OUTPUT_FILE" 2>&1
  echo "" >> "$OUTPUT_FILE"
  done

echo "Done. Results saved in $OUTPUT_FILE"