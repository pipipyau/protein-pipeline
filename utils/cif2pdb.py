import argparse
import os
import shutil
from Bio.PDB import MMCIFParser, PDBIO


def convert_cif_to_pdb(cif_file: str, pdb_file: str) -> None:
    """
    Convert a CIF file to PDB format.

    Parameters:
    - cif_file (str): Path to the input CIF file.
    - pdb_file (str): Path to the output PDB file.
    """
    try:
        parser = MMCIFParser(QUIET=True)
        structure = parser.get_structure("structure", cif_file)

        io = PDBIO()
        io.set_structure(structure)
        io.save(pdb_file)
        print(f"Converted: {cif_file} -> {pdb_file}")
    except Exception as e:
        print(f"Failed to convert {cif_file}: {e}")


def process_folder(input_folder: str) -> None:
    """
    Recursively find all .cif files in the input folder, convert them to .pdb files,
    and save to both the original location and the output folder.

    Parameters:
    - input_folder (str): Path to the input folder containing .cif files.
    """
    output_folder = os.path.join(input_folder, "output")
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for root, _, files in os.walk(input_folder):
        for file in files:
            if file.endswith(".cif"):
                cif_path = os.path.join(root, file)
                pdb_path_original = os.path.splitext(cif_path)[0] + ".pdb"
                pdb_path_output = os.path.join(output_folder,
                                               os.path.relpath(pdb_path_original,
                                                               input_folder))

                # Create necessary subdirectories in the output folder
                os.makedirs(os.path.dirname(pdb_path_output), exist_ok=True)

                # Convert and save to both locations
                convert_cif_to_pdb(cif_path, pdb_path_original)
                shutil.copy(pdb_path_original, pdb_path_output)


if __name__ == "__main__":
    # Input folder path
    parser = argparse.ArgumentParser(description='cif to PDB')
    parser.add_argument('indir', type=str, help='Path to the input folder')
    args = parser.parse_args()
    input_folder = args.indir

    if os.path.isdir(input_folder):
        process_folder(input_folder)
        print(
            f"Conversion completed for all .cif files. Output folder: {input_folder}")
    else:
        print(f"Invalid folder path: {input_folder}")
