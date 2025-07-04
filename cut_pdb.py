from Bio.PDB import PDBParser, PDBIO, Select

class ChainSelect(Select):
    def __init__(self, chain_id):
        self.chain_id = chain_id

    def accept_chain(self, chain):
        return chain.id == self.chain_id

keep_chain = 'A'
input_pdb = "/home/jovyan/git/RFdiffusion/research/input_pdb/6lzg.pdb"
output_pdb = input_pdb.replace(".pdb", "-" + ''.join(keep_chain) + ".pdb")
        
parser = PDBParser(QUIET=True)
structure = parser.get_structure("structure", input_pdb)

io = PDBIO()
io.set_structure(structure)
io.save(output_pdb, select=ChainSelect(keep_chain))