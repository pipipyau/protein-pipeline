import os
from Bio.PDB import PDBParser, PDBIO

folder_path = "/home/jovyan/git/RFdiffusion/research/outputs"
pdb_files = [
    os.path.join(folder_path, file)
    for file in os.listdir(folder_path)
    if file.endswith(".pdb") and os.path.isfile(os.path.join(folder_path, file))
]

for file_path in pdb_files:
    parser = PDBParser()
    structure = parser.get_structure("temp", file_path)
    
    io = PDBIO()
    io.set_structure(structure)
    io.save(file_path.replace(".pdb", "_upd.pdb"))