"""
Module for fasta to Alphafold3 json input conversion.
This script goes through all the subfolders and converts the fasta files to json,
saving them next to fasta.
Based on https://github.com/snufoodbiochem/Alphafold3_tools/blob/main/fasta2json.py
>> python3 fasta2json.py <input folder or fasta>
"""

import argparse
import json
import os
import re
import random


def generate_ids_with_error_handling(start_index, count):
    max_ids = 52  # Maximum IDs from A to ZA
    if start_index + count > max_ids:
        raise ValueError("ID generation exceeds the maximum allowed range of 'ZA'.")

    ids = []
    current_index = start_index

    while len(ids) < count:
        id = ""
        temp_index = current_index

        if temp_index < 26:  # A-Z
            id = chr(65 + temp_index)
        else:  # AA, BA, ..., ZA
            temp_index -= 26
            while temp_index >= 0:
                temp_index, remainder = divmod(temp_index, 26)
                id = chr(65 + remainder) + "A"
                temp_index -= 1

        ids.append(id)
        current_index += 1

    return ids


def parse_modifications(id_line, sequence_type):
    modifications = []
    matches = re.findall(r"&(\d+)_([A-Za-z]{3})", id_line)
    for match in matches:
        position = int(match[0])
        mod_type = match[1]

        if sequence_type == "protein":
            modifications.append({"ptmType": mod_type, "ptmPosition": position})
        elif sequence_type in {"dna", "rna"}:
            modifications.append(
                {"modificationType": mod_type, "basePosition": position}
            )
        elif sequence_type == "ligand":
            modifications.append({"modificationType": mod_type, "position": position})
    return modifications


def parse_bonded_atom_pairs(id_line, id_list):
    bonded_atom_pairs = []
    matches = re.findall(r"&(\d+)_([A-Za-z0-9]+)_(\d+)_([A-Za-z0-9]+)", id_line)

    for match in matches:
        atom1_position = int(match[0])
        atom1_type = match[1]
        atom2_position = int(match[2])
        atom2_type = match[3]

        for id_prefix in id_list:
            bonded_atom_pairs.append(
                [
                    [id_prefix, atom1_position, atom1_type],
                    [id_prefix, atom2_position, atom2_type],
                ]
            )

    return bonded_atom_pairs


def fasta_to_json(fasta_file):
    json_file = os.path.splitext(fasta_file)[0] + ".json"
    json_name = os.path.splitext(os.path.basename(fasta_file))[0]

    with open(fasta_file, "r") as file:
        lines = file.readlines()

    sequences = []
    current_name = None
    current_sequence = []
    last_id_end = 0
    bonded_atom_pairs = []

    for line in lines:
        line = line.strip()
        if line.startswith(">"):
            if current_name is not None:
                name_parts = current_name.split("#")
                name = name_parts[0]
                count = int(name_parts[1]) if len(name_parts) > 1 else 1
                id_list = generate_ids_with_error_handling(last_id_end, count)
                last_id_end += count

                sequence_type = "protein"
                if "dna" in current_name:
                    sequence_type = "dna"
                elif "rna" in current_name:
                    sequence_type = "rna"
                elif "ligand" in current_name:
                    sequence_type = "ligand"
                elif "smile" in current_name:
                    sequence_type = "smile"

                modifications = parse_modifications(current_name, sequence_type)

                if sequence_type in {"protein", "dna", "rna"}:
                    sequences.append(
                        {
                            sequence_type: {
                                "id": id_list,
                                "sequence": "".join(current_sequence)
                                .replace(" ", "")
                                .upper(),
                                "modifications": modifications,
                            }
                        }
                    )
                elif sequence_type == "ligand":
                    ligand_sequence = "".join(current_sequence).replace(" ", "").upper()
                    if "," in ligand_sequence:
                        ccdCodes = ligand_sequence.split(",")
                    else:
                        ccdCodes = [ligand_sequence]
                    bonded_atom_pairs.extend(
                        parse_bonded_atom_pairs(current_name, id_list)
                    )
                    sequences.append({"ligand": {"id": id_list, "ccdCodes": ccdCodes}})
                elif sequence_type == "smile":
                    sequences.append(
                        {
                            "ligand": {
                                "id": id_list,
                                "smiles": "".join(current_sequence).replace(" ", ""),
                            }
                        }
                    )

            current_name = line[1:]
            current_sequence = []
        else:
            current_sequence.append(line)

    if current_name is not None:
        name_parts = current_name.split("#")
        name = name_parts[0]
        count = int(name_parts[1]) if len(name_parts) > 1 else 1
        id_list = generate_ids_with_error_handling(last_id_end, count)
        last_id_end += count

        sequence_type = "protein"
        if "dna" in current_name:
            sequence_type = "dna"
        elif "rna" in current_name:
            sequence_type = "rna"
        elif "ligand" in current_name:
            sequence_type = "ligand"
        elif "smile" in current_name:
            sequence_type = "smile"

        modifications = parse_modifications(current_name, sequence_type)

        if sequence_type in {"protein", "dna", "rna"}:
            sequences.append(
                {
                    sequence_type: {
                        "id": id_list,
                        "sequence": "".join(current_sequence).replace(" ", "").upper(),
                        "modifications": modifications,
                    }
                }
            )
        elif sequence_type == "ligand":
            ligand_sequence = "".join(current_sequence).replace(" ", "").upper()
            if "," in ligand_sequence:
                ccdCodes = ligand_sequence.split(",")
            else:
                ccdCodes = [ligand_sequence]
            bonded_atom_pairs.extend(parse_bonded_atom_pairs(current_name, id_list))
            sequences.append({"ligand": {"id": id_list, "ccdCodes": ccdCodes}})
        elif sequence_type == "smile":
            sequences.append(
                {
                    "ligand": {
                        "id": id_list,
                        "smiles": "".join(current_sequence).replace(" ", ""),
                    }
                }
            )

    # Create random seed
    model_seeds = [random.randint(1, 100000)]

    data = {
        "name": json_name,
        "modelSeeds": model_seeds,
        "sequences": sequences,
        "bondedAtomPairs": bonded_atom_pairs,
        "dialect": "alphafold3",
        "version": 1,
    }

    with open(json_file, "w") as json_out:
        json.dump(data, json_out, indent=2)
    print(f"\nConversion complete. JSON file saved as {json_file}")


def process_folder(input_folder: str) -> None:
    """
    Recursively find all .cif files in the input folder, convert them to .pdb files,
    and save to both the original location and the output folder.

    Parameters:
    - input_folder (str): Path to the input folder containing .fasta files.
    """
    for root, _, files in os.walk(input_folder):
        for file in files:
            if file.endswith(".fasta"):
                fasta_file = os.path.join(root, file)
                fasta_to_json(fasta_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="fasta to json")
    parser.add_argument(
        "indir", type=str, help="Path to the input folder or fasta file."
    )
    args = parser.parse_args()
    input_path = args.indir

    if os.path.isdir(input_path):
        process_folder(input_path)
        print(f"Conversion completed for all .fasta files. Output folder: {input_path}")
    elif input_path.endswith(".fasta"):
        fasta_to_json(input_path)
    else:
        print(f"Invalid input path: {input_path}")
