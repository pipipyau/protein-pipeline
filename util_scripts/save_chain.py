from Bio.PDB import PDBParser, PDBIO

# Входной PDB файл
input_pdb = "/home/jovyan/protein-protein-docking/data/RBD_base/7XBG.pdb"
output_pdb = "/home/jovyan/protein-protein-docking/data/RBD_base/7XBG-A.pdb"
target_chain_id = "A"

# Чтение структуры
parser = PDBParser(QUIET=True)
structure = parser.get_structure("structure", input_pdb)

# Оставляем только нужную цепочку в первом (и обычно единственном) модели
model = structure[0]
chains_to_delete = [chain.id for chain in model if chain.id != target_chain_id]

for chain_id in chains_to_delete:
    model.detach_child(chain_id)

# Сохраняем в новый файл
io = PDBIO()
io.set_structure(structure)
io.save(output_pdb)

print(f"Сохранена только цепочка {target_chain_id} в файл {output_pdb}")