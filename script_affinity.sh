#!/bin/sh

OUTPUT_FILE="prodigy_RBD_results.txt"

> "$OUTPUT_FILE"

for pdb in $(find . -name RBD*6lzg*-complex.pdb)
do
  echo "===== Calculating for $pdb ====="
  prodigy "$pdb" --selection A Y >> "$OUTPUT_FILE" 2>&1
  echo "" >> "$OUTPUT_FILE"
  done

echo "Done. Results saved in $OUTPUT_FILE"